# Security Policy

## Supported Versions

| Version | Supported | | ------- | ------------------ | | 1.x.x | :white_check_mark: |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue, please report it responsibly.

### How to Report

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via email to: **alexey1312@users.noreply.github.com**

Include the following information in your report:

- Type of vulnerability (e.g., code injection, path traversal, information disclosure)
- Full paths of source file(s) related to the vulnerability
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the vulnerability

### What to Expect

- **Acknowledgment**: We will acknowledge receipt of your report within 48 hours.
- **Updates**: We will provide updates on the progress of addressing the vulnerability.
- **Resolution**: We aim to resolve critical vulnerabilities within 30 days.
- **Credit**: We will credit you in the release notes (unless you prefer to remain anonymous).

### Scope

This security policy applies to:

- The ExFig CLI tool
- Generated code templates
- Documentation that may contain security-relevant guidance

### Out of Scope

- Vulnerabilities in dependencies (please report these to the respective maintainers)
- Vulnerabilities requiring physical access to the user's machine
- Social engineering attacks

## Security Best Practices for Users

When using ExFig:

1. **Protect your Figma token**: Never commit your `FIGMA_PERSONAL_TOKEN` to version control. Use environment variables
   or secure secret management.

2. **Review generated code**: Always review the generated Swift/Kotlin code before integrating it into production
   applications.

3. **Keep ExFig updated**: Use the latest version to benefit from security fixes.

4. **Validate configuration files**: Ensure your `exfig.yaml` configuration comes from trusted sources.

## Acknowledgments

We appreciate the security research community's efforts in responsibly disclosing vulnerabilities. Contributors who
report valid security issues will be acknowledged here (with permission).
