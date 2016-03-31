console.log('Loading function');

// dependencies
var AWS = require('aws-sdk');
var util = require('util');
var crypto = require('crypto');
var config = require('./config.json');

// Get reference to AWS clients
var dynamodb = new AWS.DynamoDB();
var cognitoidentity = new AWS.CognitoIdentity();

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
			console.log(util.inspect(data, { showHidden: true, depth: 10 }));
			if ('Item' in data) {
				var hash = data.Item.passwordHash.S;
				var salt = data.Item.passwordSalt.S;
				var verified = data.Item.verified.BOOL;
				var user = { "email": data.Item.email.S,
							 "firstName": data.Item.firstName.S,
							 "lastName": data.Item.lastName.S,
							 "city": data.Item.city.S,
							 "state": data.Item.state.S,
							 "country": data.Item.country.S,
							 "language": data.Item.language.S,
							 "avatar": data.Item.avatar.N,
							 "lat": data.Item.lat.N,
							 "lon": data.Item.lon.N,
							 "level": data.Item.level.S };
				fn(null, hash, salt, verified, user);
			} else {
				fn(null, null); // User not found
			}
		}
	});
}

function getToken(email, fn) {
	var param = {
		IdentityPoolId: config.IDENTITY_POOL_ID,
		Logins: {} // To have provider name in a variable
	};
	param.Logins[config.DEVELOPER_PROVIDER_NAME] = email;
	cognitoidentity.getOpenIdTokenForDeveloperIdentity(param,
		function(err, data) {
			if (err) return fn(err); // an error occurred
			else fn(null, data.IdentityId, data.Token); // successful response
		});
}

exports.handler = function(event, context) {
	console.log(util.inspect(event));
	var email = event.email;
	var clearPassword = event.password;

	getUser(email, function(err, correctHash, salt, verified, user) {
		if (err) {
			context.succeed({success: false, message:'Email or password incorrect.', error: err});
		} else {
			if (correctHash == null) {
				// User not found
				console.log('User not found: ' + email);
				context.succeed({success: false, message:'Email or password incorrect.', error: 'user not found'});
			} else if (!verified) {
				// User not verified
				console.log('User not verified: ' + email);
				context.succeed({success: false, message:'Email or password incorrect.', error: 'user not verified'});
			} else {
				computeHash(clearPassword, salt, function(err, salt, hash) {
					if (err) {
						console.log("Hash error: " + err);
						context.succeed({success: false, message:'Email or password incorrect.', error: err});
					} else {
						console.log('correctHash: ' + correctHash + ' hash: ' + hash);
						if (hash == correctHash) {
							// Login ok
							console.log('User logged in: ' + email);
							getToken(email, function(err, identityId, token) {
								if (err) {
									console.log('getToken error: ' + err);
									context.succeed({success: false, message:'Unabled to log in.', error: err});
								} else {
									context.succeed({
										success: true,
										identityId: identityId,
										token: token,
										user: user
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
