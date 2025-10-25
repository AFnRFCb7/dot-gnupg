{
    inputs = { } ;
    outputs =
        { self } :
            {
                lib =
                    { coreutils , failure , ownertrust , secret-keys , writeShellApplication } :
                        let
                            implementation =
                                {
                                    init =
                                        { resources , self } :
                                            let
                                                application =
                                                    writeShellApplication
                                                        {
                                                            name = "init" ;
                                                            runtimeInputs = [ coreutils ( failure.implementation "619856fc" ) ] ;
                                                            text =
                                                                ''
                                                                    GNUPGHOME=/mount/dot-gnupg
                                                                    export GNUPGHOME
                                                                    mkdir --parents "$GNUPGHOME"
                                                                    chmod 0700 "$GNUPGHOME"
                                                                    SECRET_KEYS="$( ${ attributes.secret-keys.resource } )" || failure secret keys
                                                                    gpg --batch --yes --homedir "$GNUPGHOME" --import "$SECRET_KEYS/secret" 2>&1
                                                                    OWNERTRUST="$( ${ attributes.ownertrust.resource } )" || failure ownertrust
                                                                    gpg --batch --yes --homedir "$GNUPGHOME" --import-ownertrust "$OWNERTRUST/${ attributes.ownertrust.target }" 2>&1
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
                                            expected ,
                                            mkDerivation ,
                                            resources ? null ,
                                            self ? null
                                        } :
                                            mkDerivation
                                                {
                                                    installPhase =
                                                        ''
                                                            execute-test-attributes "$out"
                                                            execute-test-init "$out"
                                                            execute-test-targets "$out"
                                                        '' ;
                                                    name = "check" ;
                                                    nativeBuildInputs =
                                                        [
                                                            (
                                                                writeShellApplication
                                                                    {
                                                                        name = "execute-test-attributes" ;
                                                                        runtimeInputs = [ coreutils ( failure.implementation "4187683d" ) ] ;
                                                                        text =
                                                                            let
                                                                                observed = builtins.attrNames implementation ;
                                                                                in
                                                                                    if [ "init" "targets" ] == observed
                                                                                    then
                                                                                        ''
                                                                                            OUT="$1"
                                                                                            touch "$OUT"
                                                                                        ''
                                                                                    else
                                                                                        ''
                                                                                            OUT=$1
                                                                                            touch "$OUT"
                                                                                            failure attributes
                                                                                        '' ;
                                                                    }
                                                            )
                                                            (
                                                                writeShellApplication
                                                                    {
                                                                        name = "execute-test-init" ;
                                                                        runtimeInputs = [ coreutils ( failure.implementation "9507ef9d" ) ] ;
                                                                        text =
                                                                            let
                                                                                observed = builtins.toString ( implementation.init { resources = resources ; self = self ; } ) ;
                                                                            in
                                                                                if expected == observed then
                                                                                    ''
                                                                                        OUT="$1"
                                                                                        touch "$OUT"
                                                                                    ''
                                                                                else
                                                                                    ''
                                                                                        OUT="$1"
                                                                                        touch "$OUT"
                                                                                        failure init "We expected ${ expected but we observed ${ observed }"
                                                                                    '' ;
                                                                    }
                                                            )
                                                            (
                                                                writeShellApplication
                                                                    {
                                                                        name = "execute-test-targets" ;
                                                                        runtimeInputs = [ coreutils ( failure "8eadd518" ) ] ;
                                                                        text =
                                                                            let
                                                                                observed = implementation.targets ;
                                                                                in
                                                                                    if [ "dot-gnupg" ] == observed
                                                                                    then
                                                                                        ''
                                                                                            OUT="$1"
                                                                                            touch "$OUT"
                                                                                        ''
                                                                                    else
                                                                                        ''
                                                                                            OUT=$1
                                                                                            touch "$OUT"
                                                                                            failure targets
                                                                                        '' ;
                                                                    }
                                                            )
                                                        ] ;
                                                    src = ./. ;
                                                } ;
                                    implementation = implementation ;
                                } ;
                        } ;
            } ;
}