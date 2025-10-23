# Run these tests on all hosts where Docker is installed
testinfra_hosts = ['ansible://all']


def test_docker_service_running(host):
    """
    Verify that Docker service is running on the host.
    
    Different distributions may use different service names:
    - docker (most common)
    - docker.io (Debian/Ubuntu package name variant)
    - docker-engine (older Docker versions)
    """
    names = ["docker", "docker.io", "docker-engine"]
    assert any(host.service(n).is_running for n in names), \
        f"None of the Docker service names {names} are running"
