console.log('Loading function');

// dependencies
var AWS = require('aws-sdk');
var crypto = require('crypto');
var util = require('util');
var config = require('./config.json');

// Get reference to AWS clients
var dynamodb = new AWS.DynamoDB();
var ses = new AWS.SES();
var sqs = new AWS.SQS();


function createUserQueue(email, fn) {
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

	sqs.createQueue({ QueueName: fixemail }, function(err, data) {
		console.log("createQueue data: " + util.inspect(data, { showHidden: true, depth: 10 }));
		console.log("createQueue err: " + util.inspect(err, { showHidden: true, depth: 10 }));

		if(!err)
		{
			var url = data.QueueUrl;

			var policy = {
			  "Version": "2012-10-17",
			  "Id": "Queue_Policy",
			  "Statement": 
			    {
			       "Sid":"Queue_AnonymousAccess",
			       "Effect": "Allow",
			       "Principal": "*",
			       "Action": ["sqs:SendMessage","sqs:ReceiveMessage","sqs:DeleteMessage","sqs:GetQueueUrl","sqs:ChangeMessageVisibility","sqs:GetQueueAttributes"],
			       "Resource": "arn:aws:sqs:" + config.REGION + ":" + config.AWS_ACCOUNT_ID + ":" + fixemail
			    }
			}

			sqs.setQueueAttributes({
			  QueueUrl: url,
			  Attributes: {
			    Policy: JSON.stringify(policy)
			  }
			}, function(err, data) {
				console.log("setQueueAttributes data: " + util.inspect(data, { showHidden: true, depth: 10 }));
				console.log("setQueueAttributes err: " + util.inspect(err, { showHidden: true, depth: 10 }));
				fn(err);
			});
		}
		else
		{
			fn(err);			
		}
	});
}

function computeHash(password, salt, fn) {
	// Bytesize
	var len = 128;
	var iterations = 4096;

	if (3 == arguments.length) {
		crypto.pbkdf2(password, salt, iterations, len, fn);
	} else {
		fn = salt;
		crypto.randomBytes(len, function(err, salt) {
			if (err) return fn(err);
			salt = salt.toString('base64');
			crypto.pbkdf2(password, salt, iterations, len, function(err, derivedKey) {
				if (err) return fn(err);
				fn(null, salt, derivedKey.toString('base64'));
			});
		});
	}
}

function storeUser(email, password, salt, event, fn) {
	// Bytesize
	var len = 128;
	crypto.randomBytes(len, function(err, token) {
		if (err) return fn(err);
		token = token.toString('hex');
		dynamodb.putItem({
			TableName: config.DDB_TABLE,
			Item: {
				email: { S: email },
				passwordHash: { S: password },
				passwordSalt: { S: salt },

				firstName: { S: event.firstName },
				lastName: { S: event.lastName },
				city: { S: event.city },
				state: { S: event.state },
				country: { S: event.country },
				language: { S: event.language },
				avatar: { N: event.avatar.toString() },
				lat: { N: event.lat.toString() },
				lon: { N: event.lon.toString() },
				level: { S: 'listener'},

				verified: { BOOL: true }//,
//				verifyToken: { S: token }
			},
			ConditionExpression: 'attribute_not_exists (email)'
		}, function(err, data) {
			if (err) return fn(err);
			else fn(null, token);
		});
	});
}

function sendVerificationEmail(email, token, fn) {
	var subject = 'Verification Email for ' + config.EXTERNAL_NAME;
	var verificationLink = config.VERIFICATION_PAGE + '?email=' + encodeURIComponent(email) + '&verify=' + token;
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
					+ 'Please <a href="' + verificationLink + '">click here to verify your email address</a> or copy & paste the following link in a browser:'
					+ '<br><br>'
					+ '<a href="' + verificationLink + '">' + verificationLink + '</a>'
					+ '</body></html>'
				}
			}
		}
	}, fn);
}

exports.handler = function(event, context) {
	var email = event.email;
	var clearPassword = event.password;

	computeHash(clearPassword, function(err, salt, hash) {
		if (err) {
			context.fail({success: false, message: 'User already exists.', error: err});
		} else {
			storeUser(email, hash, salt, event, function(err, token) {
				if (err) {
					if (err.code == 'ConditionalCheckFailedException') {
						// userId already found
						context.fail({success: false, message: 'User already exists.', error: err});
					} else {
						context.fail({success: false, message: 'Error creating user.', error: err});
					}
				} else {
					// sendVerificationEmail(email, token, function(err, data) {
					// 	if (err) {
					// 		context.fail('Error in sendVerificationEmail: ' + err);
					// 	} else {
						createUserQueue(email, function(err) {
							context.succeed({success: true});
						});
					// 	}
					// });
				}
			});
		}
	});
}
