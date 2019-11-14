set -e
set -o pipefail
set -x

apps=( lms studio )

# Load database dumps for the largest databases to save time
./load-db.sh edxapp
./load-db.sh edxapp_csmh

# Bring edxapp containers online
for app in "${apps[@]}"; do
    docker-compose $DOCKER_COMPOSE_FILES up -d $app
done

docker-compose exec lms bash -c 'source /edx/app/edxapp/edxapp_env && cd /edx/app/edxapp/edx-platform && NO_PYTHON_UNINSTALL=1 paver install_prereqs'
docker-compose exec studio bash -c 'source /edx/app/edxapp/edxapp_env && cd /edx/app/edxapp/edx-platform && NO_PYTHON_UNINSTALL=1 paver install_prereqs'

#Installing prereqs crashes the process
docker-compose restart lms

#TODO: Fix MySQL-python installation error: this is MySQLdb version (1, 2, 5, 'final', 1), but _mysql is version (1, 4, 4, 'final', 0)
# This is a temporary fix, we will remove it once ironwood rebase is complete
#docker-compose exec lms bash -c 'source /edx/app/edxapp/edxapp_env &&
#                                  pip uninstall --disable-pip-version-check -y mysqlclient || true &&
#                                  pip uninstall --disable-pip-version-check -y MySQL-python || true &&
#                                  pip install --disable-pip-version-check MySQL-python'
#
#docker-compose exec studio bash -c 'source /edx/app/edxapp/edxapp_env &&
#                                  pip uninstall --disable-pip-version-check -y mysqlclient || true &&
#                                  pip uninstall --disable-pip-version-check -y MySQL-python || true &&
#                                  pip install --disable-pip-version-check MySQL-python'

# Run edxapp migrations first since they are needed for the service users and OAuth clients
docker-compose exec lms bash -c 'source /edx/app/edxapp/edxapp_env && cd /edx/app/edxapp/edx-platform && NO_PREREQ_INSTALL=1 paver update_db --settings devstack_docker'

# Create a superuser for edxapp
docker-compose exec lms bash -c 'source /edx/app/edxapp/edxapp_env && python /edx/app/edxapp/edx-platform/manage.py lms --settings=devstack_docker manage_user edx edx@example.com --superuser --staff'
docker-compose exec lms bash -c 'source /edx/app/edxapp/edxapp_env && echo "from django.contrib.auth import get_user_model; User = get_user_model(); user = User.objects.get(username=\"edx\"); user.set_password(\"edx\"); user.save()" | python /edx/app/edxapp/edx-platform/manage.py lms shell  --settings=devstack_docker'

# Create demo course and users
docker-compose exec lms bash -c '/edx/app/edx_ansible/venvs/edx_ansible/bin/ansible-playbook /edx/app/edx_ansible/edx_ansible/playbooks/demo.yml -v -c local -i "127.0.0.1," --extra-vars="COMMON_EDXAPP_SETTINGS=devstack_docker"'

# Fix missing vendor file by clearing the cache
docker-compose exec lms bash -c 'rm /edx/app/edxapp/edx-platform/.prereqs_cache/Node_prereqs.sha1'

# Fix Build failed running pavelib.assets.update_assets: Subprocess return code: 1
##TODO: This is a temporary fix, we will remove it once ironwood rebase is complete
#docker-compose exec lms bash -c 'source /edx/app/edxapp/edxapp_env &&
#                                  pip uninstall --disable-pip-version-check -y djangorestframework || true &&
#                                  pip install e git+https://github.com/edx/django-rest-framework.git@3c72cb5ee5baebc4328947371195eae2077197b0#egg=djangorestframework==3.2.3'
#
#docker-compose exec studio bash -c 'source /edx/app/edxapp/edxapp_env &&
#                                  pip uninstall --disable-pip-version-check -y djangorestframework || true &&
#                                  pip install e git+https://github.com/edx/django-rest-framework.git@3c72cb5ee5baebc4328947371195eae2077197b0#egg=djangorestframework==3.2.3'

# Create static assets for both LMS and Studio
for app in "${apps[@]}"; do
    docker-compose exec $app bash -c 'source /edx/app/edxapp/edxapp_env && cd /edx/app/edxapp/edx-platform && paver update_assets --settings devstack_docker'
done

# Add demo program
./programs/provision.sh lms
