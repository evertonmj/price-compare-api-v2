#create localdatabase



aws rds create-db-cluster \
    --db-cluster-identifier price-compare-db-postgres \
    --engine postgresql \
    --database-name test \
    --master-username myuser \
    --master-user-password mypassword
    --endpoint-url http://localhost:4566