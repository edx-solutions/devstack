set -e
set -o pipefail
set -x

docker-compose $DOCKER_COMPOSE_FILES up -d forum
docker-compose $DOCKER_COMPOSE_FILES exec -T forum bash -c 'source /edx/app/forum/devstack_forum_env && cd /edx/app/forum/cs_comments_service && bundle install --deployment --path /edx/app/forum/.gem/'
