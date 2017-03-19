heroku pg:backups:capture -a denguetorpedo && heroku pg:backups:url -a denguetorpedo

# To set the database of staging to the latest of production:
# heroku pg:backups:restore '' DATABASE_URL -a denguetorpedo-staging
