# Contributing to Observability Toolkit

Thank you for your interest in contributing to the Observability Toolkit! This document provides guidelines and information for contributors.

## 🚀 Getting Started

1. Fork the repository
2. Clone your fork locally
3. Create a new branch for your feature/fix
4. Make your changes
5. Test your changes thoroughly
6. Submit a pull request

## 🛠 Development Setup

```bash
# Clone the repository
git clone https://github.com/vigneshragupathy/observability-toolkit.git
cd observability-toolkit

# Copy environment configuration
cp .env.example .env

# Start the development stack
./manage-stack.sh start
```

## 📋 Contribution Guidelines

### Code Style

- Use consistent indentation (2 spaces for YAML, 4 spaces for shell scripts)
- Follow existing naming conventions
- Include comments for complex configurations
- Ensure all configuration files are properly formatted

### Adding New Components

When adding new observability components:

1. **Update Docker Compose**: Add the new service to `docker-compose.yml`
2. **Configuration**: Create appropriate configuration files in the `config/` directory
3. **Integration**: Ensure proper integration with existing components
4. **Documentation**: Update README.md with new component information
5. **Management Script**: Update `manage-stack.sh` if needed for health checks

### Configuration Changes

- Test configuration changes locally before submitting
- Provide example configurations for common use cases
- Ensure backward compatibility when possible
- Document any breaking changes

### Documentation

- Update README.md for any user-facing changes
- Include inline comments for complex configurations
- Provide examples for new features
- Update troubleshooting section if applicable

## 🧪 Testing

Before submitting a pull request:

1. **Start the stack**: `./manage-stack.sh start`
2. **Verify services**: `./manage-stack.sh status`
3. **Check health endpoints**: Test all service endpoints
4. **Test management script**: Verify all commands work correctly
5. **Clean environment**: `./manage-stack.sh cleanup` and restart

### Testing Checklist

- [ ] All services start successfully
- [ ] Health checks pass
- [ ] Configuration is valid
- [ ] No breaking changes to existing functionality
- [ ] Documentation is updated
- [ ] Management script works correctly
- [ ] External links in documentation are valid (localhost URLs are automatically ignored in CI)

## 📝 Pull Request Process

1. **Branch naming**: Use descriptive branch names (e.g., `feature/add-loki`, `fix/prometheus-config`)
2. **Commit messages**: Write clear, descriptive commit messages
3. **Description**: Provide a detailed description of changes
4. **Testing**: Include information about testing performed
5. **Documentation**: Ensure documentation is updated

### Pull Request Template

```
## Description
Brief description of the changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Tested locally
- [ ] All services start successfully
- [ ] Health checks pass
- [ ] No breaking changes

## Documentation
- [ ] README.md updated
- [ ] Configuration examples provided
- [ ] Comments added where needed
```

## 🐛 Reporting Issues

When reporting issues:

1. **Search existing issues** first
2. **Use the issue template** if available
3. **Provide details**:
   - OS and Docker version
   - Steps to reproduce
   - Expected vs actual behavior
   - Log outputs
   - Configuration details

### Issue Template

```
**Environment:**
- OS: [e.g., Ubuntu 20.04]
- Docker version: [e.g., 20.10.8]
- Docker Compose version: [e.g., 2.0.1] (specify if using `docker-compose` or `docker compose`)

**Description:**
A clear and concise description of the issue.

**Steps to Reproduce:**
1. Step 1
2. Step 2
3. Step 3

**Expected Behavior:**
What you expected to happen.

**Actual Behavior:**
What actually happened.

**Logs:**
Relevant log outputs (use code blocks).

**Additional Context:**
Any other context about the problem.
```

## 🎯 Areas for Contribution

We welcome contributions in the following areas:

### High Priority
- Additional monitoring dashboards
- Performance optimizations
- Security enhancements
- Documentation improvements

### Medium Priority
- Additional alerting rules
- Integration examples
- Configuration templates
- Troubleshooting guides

### Low Priority
- Code cleanup
- Minor bug fixes
- UI/UX improvements

## 📚 Resources

- [Docker Documentation](https://docs.docker.com/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [Jaeger Documentation](https://www.jaegertracing.io/docs/)

## 🤝 Community

- Discussion: Use GitHub Discussions for questions and ideas
- Issues: Use GitHub Issues for bug reports and feature requests
- Pull Requests: Use GitHub PRs for code contributions

## 📄 License

By contributing to this project, you agree that your contributions will be licensed under the Apache License 2.0.

## 🙏 Acknowledgments

Thank you to all contributors who help make this project better!
