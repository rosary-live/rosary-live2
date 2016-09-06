console.log('Loading function');

// dependencies
var AWS = require('aws-sdk');
var crypto = require('crypto');
var config = require('./config.json');

// Get reference to AWS clients
var dynamodb = new AWS.DynamoDB();

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
				fn(null, hash, salt);
			} else {
				fn(null, null); // User not found
			}
		}
	});
}

function updateUser(email, event, fn) {
	dynamodb.updateItem({
			TableName: config.DDB_TABLE,
			Key: {
				email: {
					S: email
				}
			},
			AttributeUpdates: {
				firstName: { Action: 'PUT', Value: { S: event.firstName } },
				lastName: { Action: 'PUT', Value: { S: event.lastName } },
				city: { Action: 'PUT', Value: { S: event.city } },
				state: { Action: 'PUT', Value: { S: event.state } },
				country: { Action: 'PUT', Value: { S: event.country } },
				language: { Action: 'PUT', Value: { S: event.language } },
				avatar: { Action: 'PUT', Value: { N: event.avatar.toString() } },
				lat: { Action: 'PUT', Value: { N: event.lat.toString() } },
				lon: { Action: 'PUT', Value: { N: event.lon.toString() } }
			}
		},
		fn);
}

function updateUserWithBroadcastRequest(email, text, fn) {
	dynamodb.updateItem({
			TableName: config.DDB_TABLE,
			Key: {
				email: {
					S: email
				}
			},
			AttributeUpdates: {
				breq: { Action: 'PUT', Value: { N: '1' } },
				reqtext: { Action: 'PUT', Value: { S: text } }
			}
		},
		fn);	
}

exports.handler = function(event, context) {
	var email = event.email;
	var password = event.password;
	var broadcastRequest = event.broadcastRequest;

	getUser(email, function(err, correctHash, salt) {
		if (err) {
			console.log('Error in getUser: ' + err);
			context.fail({success: false, message: 'Email or password incorrect.', error: err});
		} else {
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
							if(broadcastRequest != null) {
								updateUserWithBroadcastRequest(email, broadcastRequest, function(err, data) {
									if (err) {
										context.fail({success: false, message: 'Update for broadcast request failed.', error: err});
									} else {
										console.log('User updated with broadcast request: ' + email);
										context.succeed({success: true});
									}
								});
							} else {
								updateUser(email, event, function(err, data) {
									if (err) {
										context.fail({success: false, message: 'Update failed.', error: err});
									} else {
										console.log('User updated: ' + email);
										context.succeed({success: true});
									}
								});
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
	});
}
