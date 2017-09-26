/**
 * Given JSON from the OperationStore server,
 * Send a human-friendly status update to the terminal
*/
function printResponse(response, aliasToNameMap, logger) {
  const failed = response.failed.length;
  // These might get overriden for status output
  let notModified = response.not_modified.length;
  let added = response.added.length;
  if (failed) {
    // Override these to reflect reality
    notModified = 0;
    added = 0;
  }

  const addedColor = added ? 'green' : 'dim';
  logger.log(`  ${logger.colorize(addedColor, `${added} added`)}`);
  const notModifiedColor = notModified ? 'reset' : 'dim';

  logger.log(`  ${logger.colorize(notModifiedColor, `${notModified} not modified`)}`);
  const failedColor = failed ? 'red' : 'dim';
  logger.log(`  ${logger.colorize(failedColor, `${failed} failed`)}`);

  if (failed) {
    logger.error('Sync failed, errors:');
    let errors;
    Object.keys(response.errors).forEach((failedOperationAlias) => {
      if (failedOperationAlias) {
        const failedOperationName = aliasToNameMap[failedOperationAlias];
        logger.error(`  ${failedOperationName}:`);
        errors = response.errors[failedOperationAlias];
        errors.forEach((errMessage) => {
          logger.error(`    ${logger.colorize('red', '✘')} ${errMessage}`);
        });
      }
    });
  }
}

module.exports = printResponse;
