var Docker = require('dockerode-promise');
var dockerOpts = require('dockerode-options');

/**
Tiny wrapper around creating a docker instance.

@return {Dockerrode}
*/
// XXX for windows - set DOCKER_HOST=127.0.0.1:2375
module.exports = function docker() {
  return new Docker(dockerOpts());
};
