set -e
set -o pipefail
set -x

docker-compose $DOCKER_COMPOSE_FILES up -d forum
#TODO: we will not be installing our custom ruby version after upgrading forums to ironwood.
#docker-compose exec forum bash -c 'source /edx/app/forum/ruby_env && cd /edx/app/forum/cs_comments_service && bundle install --deployment --path /edx/app/forum/.gem/'
docker-compose exec forum bash -c 'source /edx/app/forum/ruby_env && source /edx/app/forum/devstack_forum_env && cd /edx/app/forum/cs_comments_service && bundle install --deployment --path /edx/app/forum/.gem/'
