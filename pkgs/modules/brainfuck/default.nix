{ pkgs, ... }:

let
  brainfuck = pkgs.haskellPackages.yabi;
in

{
  id = "brainfuck";
  name = "Brainfuck";

  packages = [
    brainfuck
  ];

  replit.runners.brainfuck = {
    name = "brainfuck";
    language = "brainfuck";
    optionalFileParam = true;
    start = "yabi \${file:-main.bf} && echo";
  };
}
