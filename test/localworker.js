var Promise = require('promise');

var fork = require('child_process').fork;

/** Binary to launch inorder to get a worker instance running */
var BINARY = __dirname + '/../bin/worker.js';


/** Wrapper for a process with a local worker with given workerType */
var LocalWorker = function(provisionerId, workerType) {
  this.provisionerId = provisionerId;
  this.workerType = workerType;
  this.process    = null;
};

/** Launch the local worker instance as a subprocess */
LocalWorker.prototype.launch = function() {
  return new Promise(function(accept, reject) {
    // Clone process environment variables.
    var envs = {};
    for (var key in process.env) {
      envs[key] = process.env[key];
    }

    // Provide commandline arguments
    var args = [
      '-c',   1,
      '--provisioner-id', this.provisionerId,
      '--worker-type', this.workerType,
      '--worker-group', 'jonasfj-local-worker',
      '--worker-id', 'who-ever-cares'
    ];

    // Launch worker process.
    var proc = this.process = fork(BINARY, args, {
      execArgv: ['--harmony'],
      env: envs,
      stdio: 'inherit'
    });

    // Listen for early exits, these are bad.
    this.process.once('exit', reject);

    // Listen for the startup event (amqp queue is bound)
    function waitForStartup(msg) {
      if (typeof msg === 'object' && msg.type === 'startup') {
        proc.removeListener('message', waitForStartup);
        proc.removeListener('exit', reject);

        accept();
      }
    }

    proc.on('message', waitForStartup);
  }.bind(this));
};

/** Terminate local worker instance */
LocalWorker.prototype.terminate = function() {
  if (this.process) {
    this.process.kill();
    this.process = null;
  }
};

// Export LocalWorker
module.exports = LocalWorker;
