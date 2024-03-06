# Truly-Builder

## Description

TrulyBuilder is a powerful PowerShell script designed to create customized Windows images (ISO files) by removing unnecessary applications, features, and components from a mounted Windows installation source. It also includes necessary scripts to automate the initial boot into an audit mode after applying the customized image. This script allows you to streamline the Windows installation process by creating a tailored image that includes only the essential components and applications you need.

## Installation

### Prerequisites

- A Windows 10/11 operating system.
- Administrative privileges are required to run the script.
- A mounted Windows ISO file or installation source.

### Steps

1. Download the latest version of the TrulyBuilder script from the official repository: [https://github.com/admarty/TrulyBuilder](https://github.com/admarty/TrulyBuilder).
2. Extract the downloaded ZIP file to a directory of your choice.
3. Run the script by opening `start_TrulyBuilder.cmd` or `start_TrulyBuilder.vbs` as an administrator.

## Usage

When you run the TrulyBuilder script, it will guide you through a series of prompts and options:

1. Select the mounted Windows ISO or installation source you want to use.
2. Choose the specific Windows image (e.g., Windows 10, Windows 11) from the mounted source.
3. Decide on the removal method (predefined list or manual selection) for Appx packages, Windows capabilities, and optional features.
4. Optionally include essential applications like Google Chrome, Notepad++, 7-Zip, and RustDesk in the customized image.
5. Review and confirm the customization options before proceeding.
6. The script will create a new customized Windows ISO file based on your selections and save it to the script folder.

## Contributing

Contributions to the TrulyBuilder project are welcome! If you encounter any issues, have suggestions for improvements, or would like to add new features, please submit a pull request or open an issue on the project's GitHub repository: [https://github.com/admarty/TrulyBuilder](https://github.com/admarty/TrulyBuilder).

## License

TrulyBuilder is licensed under the [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.en.html). See the [LICENSE](https://github.com/admarty/TrulyBuilder/blob/main/LICENSE) file for more details.

## Contact

If you have any questions, suggestions, or need further assistance, please feel free to reach out to the project maintainer, admarty, at [long025722@gmail.com](mailto:long025722@gmail.com).
