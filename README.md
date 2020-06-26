# dub-package-collector
This application collects all source code files of the
specified dub project and the source code files of all
dependencies and copies them to a specified folder.

The specified folder can be provided to e.g. 
WhiteSource Unified Agent for license / intellectual property analyzes.

Supported arguments:

| Argument  | Default value          | Description        |
| --------- | ---------------------- | ------------------ |
| --root    | Current work directory | Dub project folder |
| --folder  | whitesource            | Target folder      |
| --archive |                        | Target zip file    |
| --build   |                        | Dub build type     |
| --config  |                        | Dub config         |
