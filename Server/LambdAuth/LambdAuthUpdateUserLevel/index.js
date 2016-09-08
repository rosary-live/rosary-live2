console.log('Loading function');

// dependencies
var AWS = require('aws-sdk');
var crypto = require('crypto');
var config = require('./config.json');

// Get reference to AWS clients
var dynamodb = new AWS.DynamoDB();
var ses = new AWS.SES();

function computeHash(password, salt, fn) {
	// Bytesize
	var len = 128;
	var iterations = 4096;

	if (3 == arguments.length) {
		crypto.pbkdf2(password, salt, iterations, len, function(err, derivedKey) {
			if (err) return fn(err);
			else fn(null, salt, derivedKey.toString('base64'));
		});
	} else {
		fn = salt;
		crypto.randomBytes(len, function(err, salt) {
			if (err) return fn(err);
			salt = salt.toString('base64');
			computeHash(password, salt, fn);
		});
	}
}

function getUser(email, fn) {
	dynamodb.getItem({
		TableName: config.DDB_TABLE,
		Key: {
			email: {
				S: email
			}
		}
	}, function(err, data) {
		if (err) return fn(err);
		else {
			if ('Item' in data) {
				var hash = data.Item.passwordHash.S;
				var salt = data.Item.passwordSalt.S;
				var level = data.Item.level.S;
				fn(null, hash, salt, level);
			} else {
				fn(null, null); // User not found
			}
		}
	});
}

function updateUserLevel(email, level, fn) {
	dynamodb.updateItem({
			TableName: config.DDB_TABLE,
			Key: {
				email: {
					S: email
				}
			},
			AttributeUpdates: {
				level: { Action: 'PUT', Value: { S: level } }
			}
		},
		fn);
}

function updateUserForBroadcastApproved(email, approved, fn) {

	var updates;

	if(approved) {
		updates = { level: { Action: 'PUT', Value: { S: 'broadcaster' } },
					breq: { Action: 'DELETE' },
					reqtext: { Action: 'DELETE'} };
	} else {
		updates = { breq: { Action: 'DELETE' },
					reqtext: { Action: 'DELETE'} };
	}

	dynamodb.updateItem({
			TableName: config.DDB_TABLE,
			Key: {
				email: {
					S: email
				}
			},
			AttributeUpdates: updates
		},
		fn);
}

function sendEmail(email, approved, fn) {
	var subject = 'LiveRosary Broadcast Request ' + approved ? 'Approved' : 'Denied';
	ses.sendEmail({
		Source: config.EMAIL_SOURCE,
		Destination: {
			ToAddresses: [
				email
			]
		},
		Message: {
			Subject: {
				Data: subject
			},
			Body: {
				Html: {
					Data: '<html><head>'
					+ '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />'
					+ '<title>' + subject + '</title>'
					+ '</head><body>'
					+ approved ? 'We regret to inform you that your request for broadcaster priviledge has been denied.' :
								 'We are happy to inform you that your request for broadcaster priviledge has been approved.'
					+ '<br><br>'
					+ '</body></html>'
				}
			}
		}
	}, fn);
}

exports.handler = function(event, context) {
	var email = event.email;
	var password = event.password;
	var updateEmail = event.updateEmail;
	var updateLevel = event.updateLevel;
	var broadcastApprove = event.broadcastApprove;

	getUser(email, function(err, correctHash, salt, level) {
		if (err) {
			console.log('Error in getUser: ' + err);
			context.fail({success: false, message: 'Email or password incorrect.', error: err});
		} else {
			if(level != 'admin')
			{
				console.log('User not admin: ' + email);
				context.fail({success: false, message: 'Access denied.', error: 'User not admin'});
		}
			else
			{
				if (correctHash == null) {
					// User not found
					console.log('User not found: ' + email);
					context.fail({success: false, message: 'Email or password incorrect.', error: 'user not found'});
				} else {
					computeHash(password, salt, function(err, salt, hash) {
						if (err) {
							context.fail({success: false, message: 'Email or password incorrect.', error: err});
						} else {
							if (hash == correctHash) {	

								if(updateLevel) {
									updateUserLevel(updateEmail, updateLevel, function(err, data) {
										if (err) {
											console.log('User update failed: ' + err);
											context.fail({success: false, message: 'Update failed.', error: err});
										} else {
											console.log('User updated: ' + email);
											context.succeed({success: true});
										}
									});
								} else if(broadcastApprove != null) {
									updateUserForBroadcastApproved(updateEmail, broadcastApprove, function(err, data) {
										if (err) {
											console.log('User update failed: ' + err);
											context.fail({success: false, message: 'Update failed.', error: err});
										} else {
											console.log('User updated: ' + email);
											sendEmail(updateEmail, broadcastApprove, function(err, data) {
												if(err) console.log("Error sending email: " + err);
												context.succeed({success: true});
											});
										}
									});
								} else {
									context.fail({success: false, message: 'Bad Request.', error: 'bad request'});									
								}
							} else {
								// Login failed
								console.log('User login failed: ' + email);
								context.fail({success: false, message: 'Email or password incorrect.', error: 'login falied'});
							}
						}
					});
				}
			}
		}
	});
}
