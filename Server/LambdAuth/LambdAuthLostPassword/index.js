console.log('Loading function');

// dependencies
var AWS = require('aws-sdk');
var crypto = require('crypto');
var config = require('./config.json');

// Get reference to AWS clients
var dynamodb = new AWS.DynamoDB();
var ses = new AWS.SES();

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
				fn(null, email);
			} else {
				fn(null, null); // User not found
			}
		}
	});
}

function storeLostToken(email, fn) {
	// Bytesize
	var len = 128;
	crypto.randomBytes(len, function(err, token) {
		if (err) return fn(err);
		token = token.toString('hex');
		dynamodb.updateItem({
				TableName: config.DDB_TABLE,
				Key: {
					email: {
						S: email
					}
				},
				AttributeUpdates: {
					lostToken: {
						Action: 'PUT',
						Value: {
							S: token
						}
					}
				}
			},
		 function(err, data) {
			if (err) return fn(err);
			else fn(null, token);
		});
	});
}

function sendLostPasswordEmail(email, token, fn) {
	var subject = 'Password Lost for ' + config.EXTERNAL_NAME;
	var lostLink = config.RESET_PAGE + '?email=' + email + '&lost=' + token;
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
					+ 'Please <a href="' + lostLink + '">click here to reset your password</a> or copy & paste the following link in a browser:'
					+ '<br><br>'
					+ '<a href="' + lostLink + '">' + lostLink + '</a>'
					+ '</body></html>'
				}
			}
		}
	}, fn);
}

exports.handler = function(event, context) {
	var email = event.email;
	var link = event.link;

	getUser(email, function(err, emailFound) {
		if (err) {
			context.succeed({success: false, message: 'Error getting email', error: err});
		} else if (!emailFound) {
			console.log('User not found: ' + email);
			context.succeed({success: false, message:'Email not found.'});
		} else {
			storeLostToken(email, function(err, token) {
				if (err) {
					context.succeed({success: false, message: 'Error in storing token', error: err});
				} else {
					sendLostPasswordEmail(email, token, function(err, data) {
						if (err) {
							context.succeed({success: false, message: 'Error sending email', error: err});
						} else {
							console.log('User found: ' + email);
							context.succeed({success: true});
						}
					});
				}
			});
		}
	});
}
