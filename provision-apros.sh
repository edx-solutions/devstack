set -e
set -o pipefail
set -x

# Bring apros containers online
docker-compose $DOCKER_COMPOSE_FILES up -d mcka_apros

docker-compose exec mcka_apros bash -c 'source /edx/app/apros/venvs/mcka_apros/bin/activate && cd /edx/app/apros/mcka_apros && pip install -r requirements.txt'
docker-compose exec mcka_apros bash -c 'source /edx/app/apros/venvs/mcka_apros/bin/activate && cd /edx/app/apros/mcka_apros && python manage.py assets build'
docker-compose exec mcka_apros bash -c 'source /edx/app/apros/venvs/mcka_apros/bin/activate && cd /edx/app/apros/mcka_apros && python manage.py collectstatic --noinput'
docker-compose exec mcka_apros bash -c 'source /edx/app/apros/venvs/mcka_apros/bin/activate && cd /edx/app/apros/mcka_apros && python manage.py migrate'
