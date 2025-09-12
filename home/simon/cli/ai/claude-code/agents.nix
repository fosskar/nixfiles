{
  programs = {
    claude-code = {
      agents = {
        code-reviewer = ''
          ---
          name: code-reviewer
          description: Specialized code review agent
          tools: Read, Edit, Grep
          ---
          You are a senior software engineer specializing in code reviews.
          Focus on code quality, security, and maintainability.
        '';
        #documentation = ''
        #  ---
        #  name: documentation
        #  description: Documentation writing assistant
        #  model: claude-3-5-sonnet-20241022
        #  tools: Read, Write, Edit
        #  ---
        #  You are a technical writer who creates clear, comprehensive documentation.
        #  Focus on user-friendly explanations and examples.
        #'';
      };
    };
  };
}
