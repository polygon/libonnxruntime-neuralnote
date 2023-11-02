{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in rec {

        python_env = pkgs.python3.withPackages (ps: with ps; [
          flatbuffers
          onnxruntime
          onnx
        ]);
    
        devShell = pkgs.mkShell { buildInputs = with pkgs; [ 
          python_env 
          cmake
          bin2c
          libtool_1_5
          wget
        ]; };
      });
}
