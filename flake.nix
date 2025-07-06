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
												export GNUPGHOME=/tmp/resources/${ builtins.hashString "sha512" ( builtins.toJSON primary ) }
												if [ ! -d "$GNUPGHOME" ]
												then
													mkdir --parents "$GNUPGHOME"
													chmod 0700 "$GNUPGHOME"
													gpg --homedir "$GNUPGHOME" --batch --yes --import "$( ${ secret-keys } )"
													gpg --homedir "$GNUPGHOME" --batch --yes --import-ownertrust "( ${ ownertrust } )"
													gpg --homedir "$GNUPGHOME" --batch --yes --update-trustdb
												fi
												echo "$GNUPGHOME"
											'' ;
									} ;
							pkgs = builtins.getAttr system nixpkgs.legacyPackages ;
							in
								"${ application }/bin/application" ;
			} ;
}
