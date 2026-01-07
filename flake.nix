{
    inputs = { } ;
    outputs =
        { self } :
            {
                lib =
                    { } :
                        let
                            implementation =
                                { ownertrust , secret-keys , setup } :
                                    {
                                        init =
                                            { mount , pkgs , resources , root , wrap } :
                                                let
                                                    application =
                                                        pkgs.writeShellApplication
                                                            {
                                                                name = "init" ;
                                                                runtimeInputs =
                                                                    [
                                                                        pkgs.coreutils
                                                                        pkgs.gnupg
                                                                        (
                                                                            pkgs.writeShellApplication
                                                                                {
                                                                                    name = "setup" ;
                                                                                    runtimeInputs = [ wrap ] ;
                                                                                    text = setup ;
                                                                                }
                                                                        )
                                                                    ] ;
                                                                text =
                                                                    ''
                                                                        mkdir --parents /mount/stage
                                                                        SECRET_KEYS=${ secret-keys ( setup : setup ) }
                                                                        OWNERTRUST=${ ownertrust ( setup : setup ) }
                                                                        setup "$SECRET_KEYS" "$OWNERTRUST"
                                                                        GNUPGHOME=/mount/dot-gnupg
                                                                        export GNUPGHOME
                                                                        mkdir --parents "$GNUPGHOME"
                                                                        chmod 0700 "$GNUPGHOME"
                                                                        gpg --batch --yes --homedir "$GNUPGHOME" --import /mount/secret-keys.asc 2>&1
                                                                        gpg --batch --yes --homedir "$GNUPGHOME" --import-ownertrust /mount/ownertrust.asc 2>&1
                                                                        gpg --batch --yes --homedir "$GNUPGHOME" --update-trustdb 2>&1
                                                                    '' ;
                                                            } ;
                                                    ownertrust = ownertrust-fun { mount = mount ; pkgs = pkgs ; resources = resources ; root = root ; wrap = wrap ; } ;
                                                    secret-keys = secret-keys-fun { mount = mount ; pkgs = pkgs ; resources = resources ; root = root ; wrap = wrap ; } ;
                                                    in "${ application }/bin/init" ;
                                        targets = [ "dot-gnupg" "stage" ] ;
                                    } ;
                                in
                                    {
                                        check =
                                            {
                                                expected ? "bf5be072" ,
                                                failure ,
                                                ownertrust ,
                                                mount ? "71b99bab" ,
                                                pkgs ,
                                                resources ? "6fa37851" ,
                                                root ? "69e95c47" ,
                                                secret-keys ,
                                                setup ? "6300cec1" ,
                                                wrap ? "91db4565"
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
                                                                                    init = instance.init { mount = mount ; pkgs = pkgs ; resources = resources ; root = root ; wrap = wrap ; } ;
                                                                                    instance = implementation { ownertrust = ownertrust ; secret-keys = secret-keys ; setup = setup ; } ;
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
