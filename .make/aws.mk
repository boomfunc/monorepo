# This Makefile describes some useful aws cli operations.


# $(SHELL_VAR_DEFINED) is the lazy function shell pattern to check varibel is set and not empty.
define SHELL_VAR_DEFINED
	if [ -z "$($(1))" ]; then echo 'var $(1) is undefined'; exit 1; fi
endef


.PHONY: aws-s3-sync
aws-s3-sync:
	#### Node( '$(NODE)' ).Call( '$@' )
	@$(call SHELL_VAR_DEFINED,AWS_S3_BUCKET)
	aws s3 sync . s3://$(AWS_S3_BUCKET)/$(NODE) \
		--delete \
		--exclude 'Makefile' \
		--acl private \
		--cache-control 'public, max-age=0, s-maxage=31536000, must-revalidate'


.PHONY: aws-cf-create-invalidation
aws-cf-create-invalidation:
	#### Node( '$(NODE)' ).Call( '$@' )
	@$(call SHELL_VAR_DEFINED,DISTRIBUTION_ID)
	aws cloudfront create-invalidation \
		--distribution-id $(DISTRIBUTION_ID) \
		--paths '/$(NODE)/*'
