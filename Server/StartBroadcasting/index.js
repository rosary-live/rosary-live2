console.log('Loading function');

// dependencies
var AWS = require('aws-sdk');
var crypto = require('crypto');
var config = require('./config.json');

// Get reference to AWS clients
var dynamodb = new AWS.DynamoDB();
var sqs = new AWS.SQS();
var sns = new AWS.SNS();

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

exports.handler = function(event, context) {
	var email = event.email;
	var password = event.oldPassword;
	var bid = event.bid;

	getUser(email, function(err, correctHash, salt) {
		if (err) {
			console.log('Error in getUser: ' + err);
			context.fail({success: false, message: 'Email or password incorrect.', error: err});
		} else {
			if (correctHash == null) {
				// User not found
				console.log('User not found: ' + email);
				context.fail({success: false, message:'Email or password incorrect.', error: 'user not found'});
			} else {
				computeHash(oldPassword, salt, function(err, salt, hash) {
					if (err) {
						context.fail({success: false, message:'Email or password incorrect.', error: err});
					} else {
						if (hash == correctHash) {
							// Login ok
							console.log('User logged in: ' + email);
							computeHash(newPassword, function(err, newSalt, newHash) {
								if (err) {
									context.fail({success: false, message:'Email or password incorrect.', error: err});
								} else {
									updateUser(email, newHash, newSalt, function(err, data) {
										if (err) {
											context.fail({success: false, message: 'Update failed.', error: err});
										} else {
											console.log('User password changed: ' + email);
											context.succeed({success: true});
										}
									});
								}
							});
						} else {
							// Login failed
							console.log('User login failed: ' + email);
							context.succeed({success: false, message:'Email or password incorrect.', error: 'login failed'});
						}
					}
				});
			}
		}
	});
}
