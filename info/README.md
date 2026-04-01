Iniciar y parar docker:
    docker compose down -v
    docker compose up -d

Comprobar los logs:
    docker compose logs -f mysql
    docker exec -it cabify_mysql8 mysql -uroot -p -e "SHOW VARIABLES LIKE 'log_error%';"
    docker exec -it cabify_mysql8 mysql -uroot -p -e "SHOW VARIABLES LIKE 'slow_query_log%'; SHOW VARIABLES LIKE 'long_query_time'; SHOW VARIABLES LIKE 'slow_query_log_file';"
    docker exec -it cabify_mysql8 mysql -uroot -p -e "SHOW VARIABLES LIKE 'log_bin'; SHOW BINARY LOGS; SHOW MASTER STATUS;"