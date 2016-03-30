console.log('Loading function');

// dependencies
var AWS = require('aws-sdk');
var util = require('util');
var moment = require('moment');
var config = require('./config.json');

// Get reference to AWS clients
var dynamodb = new AWS.DynamoDB();
var ses = new AWS.SES();

function addReport(event, callback) {
	var now = moment().utc().format('X');

	// Add DDB record
	dynamodb.putItem({
		TableName: config.DDB_REPORT_TABLE,		
		Item: {
			bid: { S: event.bid },
			version: { N: event.version.toString() },
			created: { N: now },
			reporter_email: { S: event.reporter },
			reporter_name: { S: event.reporter_name },
			reason: { S: event.report },

			language: { S: event.language },
			user: { S: event.user },
			name: { S: event.name },
			city: { S: event.city },
			state: { S: event.state },
			country: { S: event.country },
			lat: { S: event.lat },
			lon: { S: event.lon },

			link: { S: event.link }
		},
		ReturnValues: 'NONE'
	}, function(err, data) {
		console.log(util.inspect(err, { showHidden: true, depth: 10 }));
		if(err) callback(err, null);
		else callback(null, data);
	});	
}

function sendReportEmail(email, event, fn) {
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

	addReport(event, function(err, result) {
		sendReportEmail('northorn@gmail.com', event, function(err, data) {
			if(err) context.fail({success:false, message: 'Failed to add report.', error:err});
			else context.succeed({success:true});
		});
	});
}
