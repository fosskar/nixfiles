use std::env;
use std::io::{self, Read, Write};
use std::net::Shutdown;
use std::os::fd::FromRawFd;
use std::os::unix::net::UnixStream;
use std::process::ExitCode;
use std::time::Duration;

const HANDSHAKE_LIMIT: usize = 64;
const HANDSHAKE_TIMEOUT: Duration = Duration::from_secs(5);

fn connect(path: &str, port: u32) -> io::Result<UnixStream> {
    let mut guest = UnixStream::connect(path)?;
    guest.set_read_timeout(Some(HANDSHAKE_TIMEOUT))?;
    guest.set_write_timeout(Some(HANDSHAKE_TIMEOUT))?;
    write!(guest, "CONNECT {port}\n")?;
    guest.flush()?;

    let mut response = [0_u8; HANDSHAKE_LIMIT];
    let mut length = 0;
    loop {
        if length == response.len() {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "hybrid-vsock response exceeds 64 bytes",
            ));
        }
        let read = guest.read(&mut response[length..length + 1])?;
        if read == 0 {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "hybrid-vsock closed during handshake",
            ));
        }
        length += read;
        if response[length - 1] == b'\n' {
            break;
        }
    }

    let response = std::str::from_utf8(&response[..length])
        .map_err(|error| io::Error::new(io::ErrorKind::InvalidData, error))?;
    let connection_id = response
        .strip_prefix("OK ")
        .and_then(|value| value.trim_end().parse::<u32>().ok())
        .filter(|value| *value != 0)
        .ok_or_else(|| {
            io::Error::new(
                io::ErrorKind::ConnectionRefused,
                format!("hybrid-vsock rejected connection: {response:?}"),
            )
        })?;
    let _ = connection_id;

    guest.set_read_timeout(None)?;
    guest.set_write_timeout(None)?;
    Ok(guest)
}

fn relay(client: UnixStream, guest: UnixStream) -> io::Result<()> {
    let mut client_reader = client.try_clone()?;
    let mut guest_writer = guest.try_clone()?;

    let guest_to_client = std::thread::spawn(move || {
        let mut guest_reader = guest;
        let mut client_writer = client;
        let result = io::copy(&mut guest_reader, &mut client_writer);
        let _ = client_writer.shutdown(Shutdown::Write);
        result
    });

    let client_result = io::copy(&mut client_reader, &mut guest_writer);
    let _ = guest_writer.shutdown(Shutdown::Write);
    let guest_result = guest_to_client
        .join()
        .map_err(|_| io::Error::other("hybrid-vsock relay thread panicked"))?;
    client_result?;
    guest_result?;
    Ok(())
}

fn run() -> io::Result<()> {
    let mut args = env::args();
    let program = args
        .next()
        .unwrap_or_else(|| "agent-vm-vsock-connect".to_owned());
    let Some(path) = args.next() else {
        return Err(io::Error::new(
            io::ErrorKind::InvalidInput,
            format!("usage: {program} <socket-path> <port>"),
        ));
    };
    let Some(port) = args.next() else {
        return Err(io::Error::new(
            io::ErrorKind::InvalidInput,
            format!("usage: {program} <socket-path> <port>"),
        ));
    };
    if args.next().is_some() {
        return Err(io::Error::new(
            io::ErrorKind::InvalidInput,
            format!("usage: {program} <socket-path> <port>"),
        ));
    }
    let port = port
        .parse::<u32>()
        .ok()
        .filter(|port| *port != 0)
        .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidInput, "invalid port"))?;

    let guest = connect(&path, port)?;
    // systemd passes the accepted stream as fd 0 and duplicates it to fd 1.
    let client = unsafe { UnixStream::from_raw_fd(0) };
    relay(client, guest)
}

fn main() -> ExitCode {
    match run() {
        Ok(()) => ExitCode::SUCCESS,
        Err(error) => {
            eprintln!("agent-vm-vsock-connect: {error}");
            ExitCode::FAILURE
        }
    }
}
