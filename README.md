# :open_file_folder: Code Printer

A robust, highly configurable, and comprehensive Bash script designed to automatically generate structured documentation for your code repositories. This tool supports multiple programming languages, profiles, syntax highlighting, filtering, and advanced options to fit various documentation needs.

---

## :bookmark_tabs: Features

* **Multiple Profiles**: Easily document projects in various languages and frameworks (`Python`, `C++`, `JavaScript`, `C#`, and more).
* **Advanced Filtering**: Include or exclude specific files, directories, and patterns with granular control.
* **Auto-detection and Profiles Inheritance**: Automatically detects and applies suitable profiles for various languages/frameworks.
* **Syntax Highlighting**: Colorizes code snippets for improved readability (requires `highlight`).
* **Detailed Statistics**: Reports comprehensive statistics including files processed, excluded, binary/text classification, and more.
* **Security**: Securely handles sensitive files by default (`*.env`, keys, credentials, etc.) unless explicitly instructed otherwise.

---

## :hammer_and_wrench: Requirements

* Bash shell (`bash`)
* GNU Core Utilities (`find`, `wc`, `head`, `awk`, `file`)
* Optional: `highlight` for syntax coloring

### Installation

Clone the repository:

```bash
git clone https://github.com/ljgonzalez1/code-printer.git
cd code-printer
```

Make the script executable:

```bash
chmod +x code_doc_generator.sh
```

---

## :rocket: Quick Usage

### Generate documentation using default profile:

```bash
./code_doc_generator.sh
```

### Using specific profiles:

```bash
./code_doc_generator.sh --profile=python --profile=django
```

### Including/excluding files:

```bash
./code_doc_generator.sh --include=src --exclude=node_modules
```

### Customizing output:

```bash
./code_doc_generator.sh --output-file=./docs/MyDocumentation.md
```

---

## :clipboard: Advanced Examples

### Comprehensive Web Development Project:

```bash
./code_doc_generator.sh --profile=nodejs --profile=react --exclude="*.min.*" --include-sensitive
```

### Large Files Handling:

```bash
./code_doc_generator.sh --profile=cpp --max-lines=3000 --max-size=5
```

### Dry-run mode (Preview Only):

```bash
./code_doc_generator.sh --profile=python --dry-run
```

---

## \:bulb: Supported Profiles

* **Programming Languages**: Python, C++, JavaScript, Java, C#, Go, Rust, PHP, Ruby, and more.
* **Frameworks and Libraries**: Django, React, Angular, Node.js, Spring, Qt, Unreal Engine, and others.
* **Development Tools**: JetBrains IDEs, Visual Studio Code, Docker, Git.
* **Operating Systems**: Windows, Linux, macOS.

To view all available profiles:

```bash
./code_doc_generator.sh --show-profiles
```

---

## \:shield: Security Features

By default, the script excludes sensitive files such as:

* Credentials (`*.key`, `*.pem`, `*.credentials`)
* Environment files (`*.env`)

To explicitly include sensitive files (use with caution):

```bash
./code_doc_generator.sh --include-sensitive
```

---

## :page_facing_up: Documentation

* **Complete Help**:

```bash
./code_doc_generator.sh --help
```

* **Quick Reference**:

```bash
./code_doc_generator.sh --tldr
```

---

## :chart_with_upwards_trend: Output Structure

Generated documentation files typically include:

* Project metadata and overview.
* Filtered directory structure.
* File-by-file content documentation with syntax highlighting.
* Detailed summary statistics (files processed, text vs binary, lines of code).

---

## :interrobang: Troubleshooting

* Ensure all dependencies are installed (`bash`, `find`, `highlight`).
* If syntax highlighting isn't working, verify installation:

```bash
highlight --version
```

---

## :scroll: License

This project is licensed under the [MIT License](LICENSE).
