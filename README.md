# C_Common_shell_files: a common set of useful bash / shell files 🧰
The purpose of this set of bash / shell files is to provide some useful files to be used alongside _JMS_ projects, such as
[C_Server_Socket](https://github.com/JonMS95/C_Server_Socket) or [C_Arg_Parse](https://github.com/JonMS95/C_Arg_Parse) among many others.

Despite its name, it can be used with C++ projects too, as the project structure is the same for both C and C++ type projects.


## Table of contents 🗂️
  - [Introduction  📑](#introduction--)
  - [Features  🌟](#features--)
  - [Prerequisites  🧱](#prerequisites--)
  - [Installation instructions  📓](#installation-instructions--)
  - [Usage  🖱️](#usage--️)
  - [To do  ☑️](#to-do--️)
  - [Related Documents  🗄️](#related-documents--️)


## Introduction <a id="introduction"></a> 📑
This library is a compilation of the most commonly used bash scripts that are used in many of my projects.

In the beginning, all of the libraries I was writing had a set of bash files that were very similar to each other. At some point, I decided
to write a downloadable set of files to be used alongside each of those projects. As a consequence, it is no longer required to write all of
those files for each project, but just to download them instead.

Note that again, this library is meant to be used alongside _JMS_ projects, not by third-party ones, as they have been designed to be used in combination with a specific files and directories structure.


## Features <a id="features"></a> 🌟
* Create directories: each project comes with its very own directory structure, as defined in its config.xml file. This feature creates those directories automatically in case they don't exist beforehand.
* Create symbolic links to dependencies: projects of any kind commonly have dependencies. Those dependencies are not copied and pasted for each project, but symbolic links are created instead. This feature manages those dependencies and generates symbolic links to them.
* Generate API versions: when building a library, header files as well as _.so_ files are generated. For each generated version, those files are stored within their corresponding API directory.


## Prerequisites <a id="prerequisites"></a> 🧱
In the following list, the minimum versions required (if any) by the library are listed.

| Dependency                   | Purpose                                 | Minimum version |
| :--------------------------- | :-------------------------------------- |:--------------: |
| [Bash][bash-link]            | Execute Bash/Shell scripts              |4.4              |
| [Git][git-link]              | Download GitHub dependencies            |2.34.1           |
| [Xmlstarlet][xmlstarlet-link]| Parse [configuration file](config.xml)  |1.6.1            |

[bash-link]:       https://www.gnu.org/software/bash/
[git-link]:        https://git-scm.com/
[xmlstarlet-link]: https://xmlstar.sourceforge.net/


## Installation instructions <a id="installation-instructions"></a> 📓
1. In order to download the repo, just clone it from GitHub to your choice path by using the [link](https://github.com/JonMS95/C_Server_Socket) to the project.

```bash
cd /path/to/repos
git clone https://github.com/JonMS95/C_Common_shell_files
```

2. Then navigate to the directory in which the repo has been downloaded, and set execution permissions to every file just in case they have not been sent beforehand.

```bash
cd /path/to/repos/C_Common_shell_files

find . -type f -exec chmod u+x {} +
```

3. To give access to other JMS libraries using this one, it should be exported to its own API directory. To do so, just apply the following:

```bash
[./src/gen_CSF_version.sh](src/gen_CSF_version.sh)
```

The result of the line above will be a new API directory (which will match the used version). Within it, a *.sh* files will be found.
- **/path/to/repos/C_Common_shell_files/API**
  - **vM_m**
    - **_directories.sh_**
    - **_gen_version.sh_**
    - **_sym_links.sh_**
    - **_gen_CSF_version.sh_**

Where **_M_** and **_m_** stand for the major and minor version numbers.


## Usage <a id="usage"></a> 🖱️
In the particular case of this library, there's not much to be said about its usage, since it's not meant to be used by itself, but in combination with another project requiring its features. In fact, each project's make file is the one calling them whenever creating directories is required, dependencies need to be managed or a new version needs to be stored in its corresponding directory.


## To do <a id="to-do"></a> ☑️
- [ ] If built-in libraries are needed but they are not installed, download and install them


## Related Documents <a id="related-documents"></a> 🗄️
* [LICENSE](LICENSE)
* [CONTRIBUTING.md](Docs/CONTRIBUTING.md)
* [CHANGELOG.md](Docs/CHANGELOG.md)

