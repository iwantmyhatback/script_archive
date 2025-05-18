# python-wrapper
### Environment variable options

* PYVENV_LOCATION ::
  * Path to the location for the Python Virtual Environment to be sourced or created & sourced in `shell/run.sh`
* LOG_LOCATION :: 
  * Path to the location for the Python log file
* REFREEZE_REQUIREMENTS ::
  * Update the requirements file with currently installed pip packages
* DOCKER_NAME ::
  * Name for the docker image that is created & run when using `shell/run_docker.sh`
* FORCE_DOCKER_REBUILD ::
  * Forced tear down and rebuild of the Docker image
  * (Re)build takes place automatically in `shell/run_docker.sh` if the `git pull` brings in a new commit for the wrapper, or the image does not already exist
* AUTO_UPDATE ::
  * Activates pull of repository changes
  * Activates pull of python container image
