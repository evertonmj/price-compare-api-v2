 docker run \
  --name local-mysql \
  -p 33061:3306 \
  -e MYSQL_ROOT_PASSWORD=p4ssw0rd \
  -d mysql:latest