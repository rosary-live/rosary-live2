console.log('Loading function');

// dependencies
var AWS = require('aws-sdk');
var crypto = require('crypto');
var config = require('./config.json');

// Get reference to AWS clients
var dynamodb = new AWS.DynamoDB();

function computeHash2(password, salt, fn) {
	// Bytesize
	var len = 128;
	var iterations = 4096;

	crypto.pbkdf2(password, salt, iterations, len, function(err, derivedKey) {
		if (err) return fn(err);
		else fn(null, salt, derivedKey.toString('base64'));
	});
}

function computeHash(password, fn) {
	// Bytesize
	var len = 128;

	crypto.randomBytes(len, function(err, salt) {
		if (err) return fn(err);
		salt = salt.toString('base64');
		computeHash2(password, salt, fn);
	});
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
			if (('Item' in data) && ('lostToken' in data.Item)) {
				var lostToken = data.Item.lostToken.S;
				fn(null, lostToken);
			} else {
				fn(null, null); // User or token not found
			}
		}
	});
}

function updateUser(email, password, salt, fn) {
	dynamodb.updateItem({
			TableName: config.DDB_TABLE,
			Key: {
				email: {
					S: email
				}
			},
			AttributeUpdates: {
				passwordHash: {
					Action: 'PUT',
					Value: {
						S: password
					}
				},
				passwordSalt: {
					Action: 'PUT',
					Value: {
						S: salt
					}
				},
				lostToken: {
					Action: 'DELETE'
				}
			}
		},
		fn);
}

exports.handler = function(event, context) {
	var email = event.email;
	var lostToken = event.token;
	var newPassword = event.newPassword;

	getUser(email, function(err, correctToken) {
		if (err) {
			context.succeed({success: false, message:'Error getting user', error: err});
		} else if (!correctToken) {
			console.log('No lostToken for user: ' + email);
			context.succeed({success: false, message:'No token for user'});
		} else if (lostToken != correctToken) {
			// Wrong token, no password lost
			console.log('Wrong lostToken for user: ' + email);
			console.log('lostToken: ' + lostToken);
			console.log('correctToken: ' + correctToken);
			context.succeed({success: false, message: 'Wrong token for user'});
		} else {
			console.log('User logged in: ' + email);
			computeHash(newPassword, function(err, newSalt, newHash) {
				if (err) {
					context.succeed({success: false, message: 'Error in computeHash', error: err});
				} else {
					updateUser(email, newHash, newSalt, function(err, data) {
						if (err) {
							context.succeed({success: false, message: 'Error in updateUser', error: err});
						} else {
							console.log('User password changed: ' + email);
							context.succeed({success: true});
						}
					});
				}
			});
		}
	});
}
