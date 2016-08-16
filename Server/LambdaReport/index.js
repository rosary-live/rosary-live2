console.log('Loading function');

// dependencies
var AWS = require('aws-sdk');
var util = require('util');
var moment = require('moment');
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
			console.log(util.inspect(data, { showHidden: true, depth: 10 }));
			if ('Item' in data) {
				var user = { "email": data.Item.email.S,
							 "name": data.Item.firstName.S + ' ' + data.Item.lastName.S,
							 "city": data.Item.city.S,
							 "state": data.Item.state.S,
							 "country": data.Item.country.S,
							 "language": data.Item.language.S,
							 "lat": data.Item.lat.N,
							 "lon": data.Item.lon.N };
				fn(null, user);
			} else {
				fn(null, null); // User not found
			}
		}
	});
}

function getBroadcast(bid, fn) {
	dynamodb.getItem({
		TableName: config.DDB_BROADCAST_TABLE,
		Key: {
			bid: {
				S: bid
			}
		}
	}, function(err, data) {
		if (err) return fn(err);
		else {
			console.log(util.inspect(data, { showHidden: true, depth: 10 }));
			if ('Item' in data) {
				var broadcast = { "bid": data.Item.bid.S,
								  "created": data.Item.created.N,
								  "updated": data.Item.updated.N,
								  "sequence": data.Item.sequence.N,
								  "email": data.Item.user.S,
								  "name": data.Item.name.S,
								  "language": data.Item.language.S,
								  "city": data.Item.city.S,
								  "state": data.Item.state.S,
								  "country": data.Item.country.S,
								  "lat": data.Item.lat.S,
								  "lon": data.Item.lon.S,
								};
				fn(null, broadcast);
			} else {
				fn(null, null); // User not found
			}
		}
	});
}

function addReport(reporter, broadcast, reason, link, callback) {
	var now = moment().utc().format('X');

	// Add DDB record
	dynamodb.putItem({
		TableName: config.DDB_REPORT_TABLE,		
		Item: {
			version: { N: "1" },
			bid: { S: broadcast.bid },
			sequence: { N: broadcast.sequence },
			reason: { S: reason },
			link: { S: link },

			created: { N: now },

			b_email: { S: broadcast.email },
			b_name: { S: broadcast.name },
			b_language: { S: broadcast.language },
			b_city: { S: broadcast.city },
			b_state: { S: broadcast.state },
			b_country: { S: broadcast.country },
			b_lat: { S: broadcast.lat },
			b_lon: { S: broadcast.lon },

			r_email: { S: reporter.email },
			r_name: { S: reporter.name },
			r_language: { S: reporter.language },
			r_city: { S: reporter.city },
			r_state: { S: reporter.state },
			r_country: { S: reporter.country },
			r_lat: { S: reporter.lat },
			r_lon: { S: reporter.lon }
		},
		ReturnValues: 'NONE'
	}, function(err, data) {
		console.log(util.inspect(err, { showHidden: true, depth: 10 }));
		if(err) callback(err, null);
		else callback(null, data);
	});	
}

function sendReportEmail(email, reporter, broadcast, reason, link, fn) {
	var subject = 'Broadcast Report for ' + event.user + ' by ' + event.reporter_name + '(' + event.reporter_email + ')';
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
					+ 'Reported broadcast link (click on phone to launch LiveRosary App): <a href="' + event.link + '">Broadcast</a>'
					+ '<br><br>'
					+ '</body></html>'
				}
			}
		}
	}, fn);
}

exports.handler = function(event, context) {
	console.log("event: " + util.inspect(event));

	getUser(event.reporter_email, function(err, reporter) {
		if(err) {
			context.succeed({success:false, message: 'Failed to get reporter.', error:err});
		} else {
			getBroadcast(event.bid, function(err, broadcast) {
				if(err) {
					context.succeed({success:false, message: 'Failed to get broadcast.', error:err});
				} else {
					addReport(reporter, broadcast, event.reason, event.link, function(err, result) {
						if(err) {
							context.succeed({success:false, message: 'Failed to add report.', error:err});
						} else {
							sendReportEmail('northorn@gmail.com', reporter, broadcast, event.reason, event.link, function(err, data) {
								if(err) context.succeed({success:false, message: 'Failed to send email.', error:err});
								else context.succeed({success:true});
							});
						}
					});
				}
			});			
		}
	});

}
