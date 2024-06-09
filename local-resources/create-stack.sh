#create localdatabase

export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"
export AWS_DEFAULT_REGION="us-east-1"
export LOCALSTACK_AUTH_TOKEN="ls-qUqEFiPA-YOmA-1271-nuso-LaCuBAFOe10a"

aws rds create-db-cluster \
    --db-cluster-identifier price-compare-db-postgres \
    --engine postgresql \
    --database-name test \
    --master-username myuser \
    --master-user-password mypassword
    --endpoint-url http://localhost:4566