{
    inputs = { } ;
    outputs =
        { self } :
            {
                lib =
                    { } :
                        let
                            implementation =
                                { ownertrust-fun , secret-keys-fun } :
                                    {
                                        init =
                                            { mount , pkgs , resources , wrap } :
                                                let
                                                    application =
                                                        pkgs.writeShellApplication
                                                            {
                                                                name = "init" ;
                                                                runtimeInputs = [ pkgs.coreutils ] ;
                                                                text =
                                                                    ''
                                                                        GNUPGHOME=/mount/dot-gnupg
                                                                        export GNUPGHOME
                                                                        mkdir --parents "$GNUPGHOME"
                                                                        chmod 0700 "$GNUPGHOME"
                                                                        SECRET_KEYS="${ secret-keys ( setup : setup ) }"
                                                                        gpg --batch --yes --homedir "$GNUPGHOME" --import "$SECRET_KEYS" 2>&1
                                                                        OWNERTRUST="${ ownertrust ( setup : setup ) }"
                                                                        gpg --batch --yes --homedir "$GNUPGHOME" --import-ownertrust "$OWNERTRUST" 2>&1
                                                                        gpg --batch --yes --homedir "$GNUPGHOME" --update-trustdb 2>&1
                                                                    '' ;
                                                            } ;
                                                    ownertrust = ownertrust-fun { mount = mount ; pkgs = pkgs ; resources = resources ; } ;
                                                    secret-keys = secret-keys-fun { mount = mount ; pkgs = pkgs ; resources = resources ; } ;
                                                    in "${ application }/bin/init" ;
                                        targets = [ "dot-gnupg" ] ;
                                    } ;
                                in
                                    {
                                        check =
                                            {
                                                expected ,
                                                failure ,
                                                ownertrust-fun ,
                                                mount ? null ,
                                                pkgs ,
                                                resources ? null ,
                                                secret-keys-fun
                                            } :
                                                pkgs.stdenv.mkDerivation
                                                    {
                                                        installPhase =
                                                            ''
                                                                execute-test "$out"
                                                            '' ;
                                                        name = "check" ;
                                                        nativeBuildInputs =
                                                            [
                                                                (
                                                                    pkgs.writeShellApplication
                                                                        {
                                                                            name = "execute-test" ;
                                                                            runtimeInputs = [ pkgs.coreutils failure ] ;
                                                                            text =
                                                                                let
                                                                                    init = instance.init { mount = mount ; pkgs = pkgs ; resources = resources ; } ;
                                                                                    instance = implementation { ownertrust-fun = ownertrust-fun ; secret-keys-fun = secret-keys-fun ; } ;
                                                                                    in
                                                                                        ''
                                                                                            OUT="$1"
                                                                                            touch "$OUT"
                                                                                            ${ if [ "init" "targets" ] != builtins.attrNames instance then ''failure 0d792ffc "We expected the dot-gnupg names to be init targets but we observed ${ builtins.toJSON ( builtins.attrNames instance ) }"'' else "#" }
                                                                                            ${ if expected != init then ''failure b2ba9748 "We expected the dot-gnupg init to be ${ builtins.toString expected } but we observed ${ builtins.toString init }"'' else "#" }
                                                                                            ${ if [ "dot-gnupg" ] != instance.targets then ''failure 63d0da9f "We expected the dot-gnupg targets to be dot-gnupg but we observed ${ builtins.toJSON instance.targets }"'' else "#" }
                                                                                        '' ;
                                                                        }
                                                                )
                                                            ] ;
                                                        src = ./. ;
                                                    } ;
                                        implementation = implementation ;
                                    } ;
            } ;
}