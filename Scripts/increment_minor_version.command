cd "$( dirname "${BASH_SOURCE[0]}" )"
cd ..
perl -i -pe 's/\b(\d+)(?=\D*$)/$1+1/e' ExFig.podspec
perl -i -pe 's/\b(\d+)(?=\D*$)/$1+1/e' ./Sources/ExFigCLI/ExFigCommand.swift
