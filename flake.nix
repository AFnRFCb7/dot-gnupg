{
	inputs = { } ;
	outputs =
		{ self } :
			{
				lib.implementation =
					{
						nixpkgs ,
						ownertrust ,
						secret-keys ,
						system
					} @primary :
						let
							application =	
								pkgs.writeShellApplication
									{
										name = "application" ;
										runtimeInputs = [ pkgs.coreutils pkgs.gnupg ] ;
										text =	
											''
												export GNUPHOME=/tmp/resources/${ builtins.hashString "sha512" ( builtins.toJSON primary ) }
												mkdir --parents "$GNUPGHOME"
												chown 07000 "$GNUPGHOME"
												gpg --homedir "$GNUPGHOME" --batch --yes --import-secret-keys "$( ${ secret-keys } )"
												gpg --homedir "$GNUPGHOME" --batch --yes --import-ownertrust "( ${ ownertrust } )"
												gpg --homedir "$GNUPGHOME"" --batch --yes --update-trustdb
											'' ;
									} ;
							pkgs = builtins.getAttr system nixpkgs.legacyPackages ;
							in
								"${ application }/bin/application" ;
			} ;
}
