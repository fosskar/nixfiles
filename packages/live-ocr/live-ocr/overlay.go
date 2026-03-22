package main

import (
	"fmt"
	"image"
	"image/color"
	"math"
	"os"
	"sort"

	"gioui.org/app"
	"gioui.org/f32"
	"gioui.org/io/key"
	"gioui.org/io/pointer"
	"gioui.org/io/event"
	"gioui.org/io/system"
	"gioui.org/unit"
	"gioui.org/layout"
	"gioui.org/op"
	"gioui.org/op/clip"
	"gioui.org/op/paint"
	"gioui.org/text"
	"gioui.org/widget/material"
)

type overlayState struct {
	words    []Word
	selected map[int]bool
	img      image.Image
	imgOp    paint.ImageOp
	imgW     int
	imgH     int
	// scaling
	scale   float32
	offsetX float32
	offsetY float32
	// drag
	dragging  bool
	dragMulti bool
	dragX0    float32
	dragY0    float32
	dragX1    float32
	dragY1    float32
	// last clicked word index for shift+click range
	lastClicked int
}

const barHeight = 24

func showOverlay(imgData []byte, words []Word) error {
	img, err := decodeImage(imgData)
	if err != nil {
		return fmt.Errorf("decode image: %w", err)
	}

	state := &overlayState{
		words:    words,
		selected:    make(map[int]bool),
		lastClicked: -1,
		img:      img,
		imgOp:    paint.NewImageOp(img),
		imgW:     img.Bounds().Dx(),
		imgH:     img.Bounds().Dy(),
	}

	go func() {
		w := new(app.Window)
		winW := state.imgW
		if winW < 450 {
			winW = 450
		}
		winH := state.imgH + barHeight
		if winH < 200 {
			winH = 200
		}
		w.Option(
			app.Title("live-ocr"),
			app.Size(unit.Dp(winW), unit.Dp(winH)),
		)
		if err := runOverlay(w, state); err != nil {
			fmt.Fprintf(os.Stderr, "overlay error: %v\n", err)
		}
		os.Exit(0)
	}()

	app.Main()
	return nil
}

func runOverlay(w *app.Window, state *overlayState) error {
	th := material.NewTheme()
	var ops op.Ops

	for {
		switch e := w.Event().(type) {
		case app.DestroyEvent:
			return e.Err

		case app.FrameEvent:
			gtx := app.NewContext(&ops, e)

			// handle keys
			for {
				ev, ok := gtx.Event(
					key.Filter{Name: key.NameEscape},
					key.Filter{Name: key.NameReturn},
					key.Filter{Name: "C", Required: key.ModCtrl},
					key.Filter{Name: "A", Required: key.ModCtrl},
				)
				if !ok {
					break
				}
				if ke, ok := ev.(key.Event); ok && ke.State == key.Press {
					switch {
					case ke.Name == key.NameEscape:
						w.Perform(system.ActionClose)
						return nil
					case ke.Name == key.NameReturn:
						copySelected(state)
						w.Perform(system.ActionClose)
						return nil
					case ke.Name == "C" && ke.Modifiers.Contain(key.ModCtrl):
						copySelected(state)
						w.Perform(system.ActionClose)
						return nil
					case ke.Name == "A" && ke.Modifiers.Contain(key.ModCtrl):
						for i := range state.words {
							state.selected[i] = true
						}
					}
				}
			}

			// handle pointer events
			handlePointer(gtx, state)

			// draw
			drawFrame(gtx, th, state)

			// request keyboard focus
			gtx.Execute(key.FocusCmd{Tag: w})

			e.Frame(gtx.Ops)
		}
	}
}

func handlePointer(gtx layout.Context, state *overlayState) {
	// register pointer input area
	area := clip.Rect{Max: gtx.Constraints.Max}.Push(gtx.Ops)
	event.Op(gtx.Ops, state)
	area.Pop()

	for {
		ev, ok := gtx.Event(pointer.Filter{Target: state, Kinds: pointer.Press | pointer.Drag | pointer.Release})
		if !ok {
			break
		}
		if pe, ok := ev.(pointer.Event); ok {
			ctrl := pe.Modifiers.Contain(key.ModCtrl)
			shift := pe.Modifiers.Contain(key.ModShift)

			switch pe.Kind {
			case pointer.Press:
				state.dragging = true
				state.dragX0 = pe.Position.X
				state.dragY0 = pe.Position.Y
				state.dragX1 = pe.Position.X
				state.dragY1 = pe.Position.Y
				state.dragMulti = ctrl

			case pointer.Drag:
				state.dragX1 = pe.Position.X
				state.dragY1 = pe.Position.Y

			case pointer.Release:
				state.dragX1 = pe.Position.X
				state.dragY1 = pe.Position.Y
				dx := state.dragX1 - state.dragX0
				dy := state.dragY1 - state.dragY0

				if math.Sqrt(float64(dx*dx+dy*dy)) < 5 {
					// click
					ix, iy := screenToImg(state, pe.Position.X, pe.Position.Y)
					idx := wordAt(state, ix, iy)
					if shift && state.lastClicked >= 0 && idx >= 0 {
						// shift+click: select range between last clicked and this
						lo, hi := state.lastClicked, idx
						if lo > hi {
							lo, hi = hi, lo
						}
						state.selected = make(map[int]bool)
						for j := lo; j <= hi; j++ {
							state.selected[j] = true
						}
					} else if ctrl {
						// ctrl+click: toggle individual word
						if idx >= 0 {
							if state.selected[idx] {
								delete(state.selected, idx)
							} else {
								state.selected[idx] = true
							}
						}
					} else {
						// plain click: replace selection or deselect
						if idx >= 0 && len(state.selected) == 1 && state.selected[idx] {
							// clicking the only selected word deselects it
							state.selected = make(map[int]bool)
						} else {
							state.selected = make(map[int]bool)
							if idx >= 0 {
								state.selected[idx] = true
							}
						}
					}
					if idx >= 0 {
						state.lastClicked = idx
					}
				} else {
					// drag select
					if !state.dragMulti {
						state.selected = make(map[int]bool)
					}
					handleDragSelect(state)
				}
				state.dragging = false
			}
		}
	}
}

func drawFrame(gtx layout.Context, th *material.Theme, state *overlayState) {
	winW := float32(gtx.Constraints.Max.X)
	winH := float32(gtx.Constraints.Max.Y)
	imgAreaH := winH - barHeight

	// calculate scaling to fit image above status bar
	scaleX := winW / float32(state.imgW)
	scaleY := imgAreaH / float32(state.imgH)
	state.scale = min32(scaleX, scaleY)
	state.offsetX = (winW - float32(state.imgW)*state.scale) / 2
	state.offsetY = (imgAreaH - float32(state.imgH)*state.scale) / 2

	// black background
	paint.Fill(gtx.Ops, color.NRGBA{A: 255})

	// draw image
	imgStack := op.Offset(image.Pt(int(state.offsetX), int(state.offsetY))).Push(gtx.Ops)
	imgAffine := op.Affine(f32.Affine2D{}.Scale(f32.Pt(0, 0), f32.Pt(state.scale, state.scale))).Push(gtx.Ops)
	state.imgOp.Add(gtx.Ops)
	paint.PaintOp{}.Add(gtx.Ops)
	imgAffine.Pop()
	imgStack.Pop()

	// semi-transparent overlay
	paint.Fill(gtx.Ops, color.NRGBA{A: 77})

	// draw word boxes
	for i, w := range state.words {
		sx := state.offsetX + float32(w.X)*state.scale
		sy := state.offsetY + float32(w.Y)*state.scale
		sw := float32(w.W) * state.scale
		sh := float32(w.H) * state.scale

		rect := image.Rect(int(sx), int(sy), int(sx+sw), int(sy+sh))

		if state.selected[i] {
			stack := clip.Rect(rect).Push(gtx.Ops)
			paint.Fill(gtx.Ops, color.NRGBA{R: 51, G: 128, B: 255, A: 102})
			stack.Pop()
			drawBorder(gtx.Ops, rect, color.NRGBA{R: 77, G: 153, B: 255, A: 204}, 2)
		} else {
			drawBorder(gtx.Ops, rect, color.NRGBA{R: 255, G: 255, B: 255, A: 38}, 1)
		}
	}

	// drag rectangle
	if state.dragging {
		x0 := min32(state.dragX0, state.dragX1)
		y0 := min32(state.dragY0, state.dragY1)
		x1 := max32(state.dragX0, state.dragX1)
		y1 := max32(state.dragY0, state.dragY1)
		rect := image.Rect(int(x0), int(y0), int(x1), int(y1))

		stack := clip.Rect(rect).Push(gtx.Ops)
		paint.Fill(gtx.Ops, color.NRGBA{R: 51, G: 128, B: 255, A: 38})
		stack.Pop()
		drawBorder(gtx.Ops, rect, color.NRGBA{R: 77, G: 153, B: 255, A: 153}, 1)
	}

	// status bar
	drawStatusBar(gtx, th, state, int(winW), int(winH))
}

func drawBorder(ops *op.Ops, rect image.Rectangle, c color.NRGBA, width int) {
	// top
	s := clip.Rect{Min: rect.Min, Max: image.Pt(rect.Max.X, rect.Min.Y+width)}.Push(ops)
	paint.Fill(ops, c)
	s.Pop()
	// bottom
	s = clip.Rect{Min: image.Pt(rect.Min.X, rect.Max.Y-width), Max: rect.Max}.Push(ops)
	paint.Fill(ops, c)
	s.Pop()
	// left
	s = clip.Rect{Min: rect.Min, Max: image.Pt(rect.Min.X+width, rect.Max.Y)}.Push(ops)
	paint.Fill(ops, c)
	s.Pop()
	// right
	s = clip.Rect{Min: image.Pt(rect.Max.X-width, rect.Min.Y), Max: rect.Max}.Push(ops)
	paint.Fill(ops, c)
	s.Pop()
}

func drawStatusBar(gtx layout.Context, th *material.Theme, state *overlayState, width, height int) {
	barY := height - barHeight

	// separator line
	sep := clip.Rect{Min: image.Pt(0, barY), Max: image.Pt(width, barY+1)}.Push(gtx.Ops)
	paint.Fill(gtx.Ops, color.NRGBA{R: 255, G: 255, B: 255, A: 40})
	sep.Pop()

	// background
	barRect := image.Rect(0, barY+1, width, height)
	stack := clip.Rect(barRect).Push(gtx.Ops)
	paint.Fill(gtx.Ops, color.NRGBA{R: 18, G: 18, B: 24, A: 240})
	stack.Pop()

	nSelected := len(state.selected)
	var msg string
	if nSelected > 0 {
		msg = fmt.Sprintf("%d selected · Enter to copy", nSelected)
	} else {
		msg = fmt.Sprintf("%d words copied · click to refine · Ctrl+A all", len(state.words))
	}

	lbl := material.Caption(th, msg)
	lbl.Color = color.NRGBA{R: 160, G: 160, B: 175, A: 180}
	lbl.Alignment = text.Start

	barOffset := op.Offset(image.Pt(8, barY+5)).Push(gtx.Ops)
	lbl.Layout(gtx)
	barOffset.Pop()
}

func screenToImg(state *overlayState, sx, sy float32) (float32, float32) {
	ix := (sx - state.offsetX) / state.scale
	iy := (sy - state.offsetY) / state.scale
	return ix, iy
}

func handleDragSelect(state *overlayState) {
	x0, y0 := screenToImg(state, min32(state.dragX0, state.dragX1), min32(state.dragY0, state.dragY1))
	x1, y1 := screenToImg(state, max32(state.dragX0, state.dragX1), max32(state.dragY0, state.dragY1))

	for i, w := range state.words {
		wx := float32(w.X)
		wy := float32(w.Y)
		wx2 := wx + float32(w.W)
		wy2 := wy + float32(w.H)

		if wx2 >= x0 && wx <= x1 && wy2 >= y0 && wy <= y1 {
			state.selected[i] = true
		}
	}
}

func wordAt(state *overlayState, ix, iy float32) int {
	for i, w := range state.words {
		if ix >= float32(w.X) && ix <= float32(w.X+w.W) &&
			iy >= float32(w.Y) && iy <= float32(w.Y+w.H) {
			return i
		}
	}
	return -1
}

func copySelected(state *overlayState) {
	if len(state.selected) == 0 {
		return
	}

	type indexedWord struct {
		idx  int
		word Word
	}

	var sel []indexedWord
	for i := range state.selected {
		sel = append(sel, indexedWord{i, state.words[i]})
	}

	sort.Slice(sel, func(a, b int) bool {
		wa, wb := sel[a].word, sel[b].word
		lineThreshold := (wa.H + wb.H) / 2
		if intAbs(wa.Y-wb.Y) < lineThreshold {
			return wa.X < wb.X
		}
		return wa.Y < wb.Y
	})

	var result string
	var lastY int
	for i, sw := range sel {
		if i > 0 {
			lineThreshold := (sw.word.H + sel[i-1].word.H) / 2
			if intAbs(sw.word.Y-lastY) >= lineThreshold {
				result += "\n"
			} else {
				result += " "
			}
		}
		result += sw.word.Text
		lastY = sw.word.Y
	}

	if err := copyToClipboard(result); err != nil {
		notify("live-ocr", fmt.Sprintf("copy failed: %v", err))
	} else {
		notify("live-ocr", fmt.Sprintf("copied %d words", len(sel)))
	}
}

func intAbs(x int) int {
	if x < 0 {
		return -x
	}
	return x
}

func min32(a, b float32) float32 {
	if a < b {
		return a
	}
	return b
}

func max32(a, b float32) float32 {
	if a > b {
		return a
	}
	return b
}
