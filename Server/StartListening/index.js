console.log('Loading function');

// dependencies
var AWS = require('aws-sdk');
var util = require('util');
//var crypto = require('crypto');
var config = require('./config.json');

// Get reference to AWS clients
//var dynamodb = new AWS.DynamoDB();
//var sqs = new AWS.SQS();
var sns = new AWS.SNS();

// function computeHash(password, salt, fn) {
// 	// Bytesize
// 	var len = 128;
// 	var iterations = 4096;

// 	if (3 == arguments.length) {
// 		crypto.pbkdf2(password, salt, iterations, len, function(err, derivedKey) {
// 			if (err) return fn(err);
// 			else fn(null, salt, derivedKey.toString('base64'));
// 		});
// 	} else {
// 		fn = salt;
// 		crypto.randomBytes(len, function(err, salt) {
// 			if (err) return fn(err);
// 			salt = salt.toString('base64');
// 			computeHash(password, salt, fn);
// 		});
// 	}
// }

// function getUser(email, fn) {
// 	dynamodb.getItem({
// 		TableName: config.DDB_TABLE,
// 		Key: {
// 			email: {
// 				S: email
// 			}
// 		}
// 	}, function(err, data) {
// 		if (err) return fn(err);
// 		else {
// 			if ('Item' in data) {
// 				var hash = data.Item.passwordHash.S;
// 				var salt = data.Item.passwordSalt.S;
// 				fn(null, hash, salt);
// 			} else {
// 				fn(null, null); // User not found
// 			}
// 		}
// 	});
// }

function subscribeToTopic(bid, email, fn) {
	var fixemail = email.replace('@','-')
				 .replace('.', '-')
				 .replace('!', '_')
				 .replace('#', '_')
				 .replace('$', '_')
				 .replace('%', '_')
				 .replace('&', '_')
				 .replace("'", '_')
				 .replace('*', '_')
				 .replace('+', '_')
				 .replace('\/', '_')
				 .replace('=', '_')
				 .replace('?', '_')
				 .replace('^', '_')
				 .replace('`', '_')
				 .replace('{', '_')
				 .replace('|', '_')
				 .replace('}', '_')
				 .replace('~', '_');

	console.log("fixemail:" + fixemail);

	sns.subscribe({
	    'TopicArn': "arn:aws:sns:" + config.REGION + ":" + config.AWS_ACCOUNT_ID + ":" + bid,
	    'Protocol': 'sqs',
	    'Endpoint': "arn:aws:sqs:" + config.REGION + ":" + config.AWS_ACCOUNT_ID + ":" + fixemail
	}, function(err, data) {
		console.log("subscribe data: " + util.inspect(data, { showHidden: true, depth: 10 }));
		console.log("subscribe err: " + util.inspect(err, { showHidden: true, depth: 10 }));

		sns.setSubscriptionAttributes({ SubscriptionArn: data.SubscriptionArn,
										AttributeName: "RawMessageDelivery",
										AttributeValue: "true"}, function(err, data) {
			console.log("setSubscriptionAttributes data: " + util.inspect(data, { showHidden: true, depth: 10 }));
			console.log("setSubscriptionAttributes err: " + util.inspect(err, { showHidden: true, depth: 10 }));
			fn(err);			
		});
	});
}

exports.handler = function(event, context) {
	var email = event.email;
//	var password = event.password;
	var bid = event.bid;

	// getUser(email, function(err, correctHash, salt) {
	// 	if (err) {
	// 		console.log('Error in getUser: ' + err);
	// 		context.fail({success: false, message: 'Email or password incorrect.', error: err});
	// 	} else {
	// 		if (correctHash == null) {
	// 			// User not found
	// 			console.log('User not found: ' + email);
	// 			context.fail({success: false, message:'Email or password incorrect.', error: 'user not found'});
	// 		} else {
	// 			computeHash(password, salt, function(err, salt, hash) {
	// 				if (err) {
	// 					context.fail({success: false, message:'Email or password incorrect.', error: err});
	// 				} else {
	// 					if (hash == correctHash) {
	// 						// Login ok
	// 						console.log('User logged in: ' + email);
							subscribeToTopic(bid, email, function(err) {
								if (err) {
									context.fail({success: false, message: 'Failed to subscribe to topic.', error: err});
								} else {
									context.succeed({success: true});
								}
							});
	// 					} else {
	// 						// Login failed
	// 						console.log('User login failed: ' + email);
	// 						context.succeed({success: false, message:'Email or password incorrect.', error: 'login failed'});
	// 					}
	// 				}
	// 			});
	// 		}
	// 	}
	// });
}
