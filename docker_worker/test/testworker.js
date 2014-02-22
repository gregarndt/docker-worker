/**
 * This module spawns an instance of the worker, then submits a given task for
 * this automatically generated workerType and listens for the task completion
 * event.
 */

var LocalWorker = require('./localworker');
var queue       = require('../queue');
var uuid        = require('uuid');
var Promise     = require('promise');
var Listener    = require('./listener');

/** Test provisioner id, don't change this... */
exports.TEST_PROVISIONER_ID = 'jonasfj-says-dont-provision-this';

/** Wait for a message, fetch result and stop listening */
var waitForResult = function(listener) {
  return new Promise(function(accept, reject) {
    listener.once('message', function(message) {
      // Stop listening
      listener.destroy();
      // Request the result.json from resultUrl in completion message
      request
        .get(message.resultUrl)
        .end(function(res) {
          if (res.ok) {
            accept(res.body);
          } else {
            debug("Failed to get result.json from task completion message");
            reject(res.text);
          }
        });
    });
  });
};

/** This will submit a task with given payload to a worker instance running
 * locally and wait for the result to be published to S3. Then fetch the
 * result from S3 and return it from the promise.
 *
 * This is accomplished by posting task with provisionerId,
 * `jonasfj-says-dont-provision-this` with a UUID for workerType, so that we're
 * sure the task will only be picked up by our local worker.
 */
exports.submitTaskAndGetResults = function(payload) {
  var workerType = uuid.v4();

  // Start listening for a result from the worker type
  var listener = new Listener(workerType);
  var started_listening = listener.listen();

  // Post task to queue
  var task_posted = started_listening.then(function() {
    return queue.postTask(payload, {
      provisionerId:    exports.TEST_PROVISIONER_ID,
      workerType:       workerType,
      owner:            'unknown@localhost.local',
      name:             'Task from docker-worker test suite',
      deadline:         1
    });
  });

  // Create local worker and launch it
  var worker = new LocalWorker(workerType);
  var worker_running = task_posted.then(function() {
    return worker.launch();
  });

  // Wait for a result to be posted
  var got_result = worker_running.then(function() {
    return waitForResult(listener);
  });

  // Kill worker when we've got the result
  return got_result.then(function(result) {
    worker.kill();
    return result;
  }, function(err) {
    worker.kill();
    debug("Got error in testworker: %s as JSON: %j", err, err);
    throw err;
  });
};

