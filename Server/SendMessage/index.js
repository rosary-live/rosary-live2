console.log('Loading function');

// dependencies
var AWS = require('aws-sdk');
var util = require('util');
//var crypto = require('crypto');
var config = require('./config.json');

// Get reference to AWS clients
//var dynamodb = new AWS.DynamoDB();
var sqs = new AWS.SQS();
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

function sendToUser(email, message, fn) {
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
	sqs.sendMessage({ MessageBody: JSON.stringify(message),
					  QueueUrl: "https://sqs." + config.REGION + ".amazonaws.com/" + config.AWS_ACCOUNT_ID + "/" + fixemail,
					  DelaySeconds: 0
	}, function(err, data) {
		console.log("sendMessage data: " + util.inspect(data, { showHidden: true, depth: 10 }));
		console.log("sendMessage err: " + util.inspect(err, { showHidden: true, depth: 10 }));
		fn(err);			
	});
}

function sendToBroadcast(bid, message, fn) {
	sns.publish({ Message: { default: JSON.stringify(message), sqs: JSON.stringify(message) },
				  MessageStructure: 'json',
				  TopicArn: "arn:aws:sns:" + config.REGION + ":" + config.AWS_ACCOUNT_ID + ":" + bid

	}, function(err, data) {
		console.log("publish data: " + util.inspect(data, { showHidden: true, depth: 10 }));
		console.log("publish err: " + util.inspect(err, { showHidden: true, depth: 10 }));
		fn(err);			
	});
}

exports.handler = function(event, context) {
	if(event.email) {
		sendToUser(event.email, event.message, function(err) {
			if (err) {
				context.fail({success: false, message: 'Failed to end to queue.', error: err});
			} else {
				context.succeed({success: true});
			}
		});
	} else if(event.bid) {
		sendToBroadcast(event.bid, event.message, function(err) {
			if (err) {
				context.fail({success: false, message: 'Failed to publish to topic.', error: err});
			} else {
				context.succeed({success: true});
			}
		});
	}
	else
	{
		context.fail({success: false, message: 'Invalid parameters.'});
	}

	//var email = event.email;
//	var password = event.password;
	//var bid = event.bid;

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
							// subscribeToTopic(bid, email, function(err) {
								// if (err) {
								// 	context.fail({success: false, message: 'Failed to subscribe to topic.', error: err});
								// } else {
								// 	context.succeed({success: true});
							// 	}
							// });
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
