# 6d1a0db1
{
    inputs = { } ;
    outputs =
        { self } :
            {
                lib =
                    { } :
                        let
                            implementation =
                                { ownertrust , ownertrust-file , secret-keys , secret-keys-file } :
                                    {
                                        init =
                                            { mount , pkgs , resources , root , wrap } @primary :
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
                                                                                    name = "ownertrust-program" ;
                                                                                    runtimeInputs = [ pkgs.coreutils ] ;
                                                                                    text = ownertrust-file ;
                                                                                }
                                                                        )
                                                                        (
                                                                            pkgs.writeShellApplication
                                                                                {
                                                                                    name = "secret-keys-program" ;
                                                                                    runtimeInputs = [ pkgs.coreutils ] ;
                                                                                    text = secret-keys-file ;
                                                                                }
                                                                        )
                                                                    ] ;
                                                                text =
                                                                    ''
                                                                        SECRET_KEYS=${ secret-keys primary ( setup : setup ) }
                                                                        SECRET_KEYS_FILE="$( secret-keys-program "$SECRET_KEYS" )" || failure 4a6ea680
                                                                        OWNERTRUST=${ ownertrust primary ( setup : setup ) }
                                                                        OWNERTRUST_FILE="$( ownertrust-program "$OWNERTRUST" )" || failure 5751796b
                                                                        GNUPGHOME=/mount/dot-gnupg
                                                                        export GNUPGHOME
                                                                        mkdir --parents "$GNUPGHOME"
                                                                        chmod 0700 "$GNUPGHOME"
                                                                        gpg --batch --yes --homedir "$GNUPGHOME" --import "$SECRET_KEYS_FILE" 2>&1
                                                                        gpg --batch --yes --homedir "$GNUPGHOME" --import-ownertrust "$OWNERTRUST_FILE" 2>&1
                                                                        gpg --batch --yes --homedir "$GNUPGHOME" --update-trustdb 2>&1
                                                                    '' ;
                                                            } ;
                                                    in "${ application }/bin/init" ;
                                        targets = [ "dot-gnupg" ] ;
                                    } ;
                                in
                                    {
                                        check =
                                            {
                                                expected ? "bf5be072" ,
                                                failure ,
                                                ownertrust ,
                                                ownertrust-file ,
                                                mount ? "71b99bab" ,
                                                pkgs ,
                                                resources ? "6fa37851" ,
                                                root ? "69e95c47" ,
                                                secret-keys ,
                                                secret-keys-file ,
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
                                                                                    instance = implementation { ownertrust = ownertrust ; ownertrust-file = ownertrust-file ; secret-keys = secret-keys ; secret-keys-file = secret-keys-file ; } ;
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
