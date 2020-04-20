# Fr24feed, FlightAware and RadarBox with dump1090 as a Docker image for Raspberry Pi (armhf)

armhf-RPi docker image of Fr24feed, FlightAware, RadarBox and dump1090.

Feed FlightRadar24, FlightAware and RadarBox services and allow you to see the positions of aircrafts on a map.

---

![Image of dump1090 webapp](https://raw.githubusercontent.com/thomasreiser/flightfeeder/master/screenshot.png)

# Requirements
- Docker
- RTL-SDR DVBT USB Dongle (RTL2832)

# Getting started

Run : 
```
docker run -d -p 8080:8080 -p 8754:8754 \
	--device=/dev/bus/usb:/dev/bus/usb \
	-e "FR24FEED_FR24KEY=MY_SHARING_KEY" \
	-e "PIAWARE_FEEDER_DASH_ID=MY_FEEDER_ID" \
	-e "RBFEEDER_KEY=MY_SHARING_KEY" \
	-e "HTML_SITE_LAT=MY_SITE_LAT" \
	-e "HTML_SITE_LON=MY_SITE_LON" \
	-e "HTML_SITE_NAME=MY_SITE_NAME" \
	-e "PANORAMA_ID=MY_PANORAMA_ID" \
	thomasreiser/flightfeeder
```

Go to http://dockerhost:8080 to view a map of reveived data.
Go to http://dockerhost:8754 to view fr24feed configuration panel.

*Note : remove `-e "PANORAMA_ID=MY_PANORAMA_ID"` from the command line if you don't want to use this feature.*

# Configuration

## Common

To disable starting a service you can add an environment variable :

| Environment Variable                  | Value                    | Description               |
|---------------------------------------|--------------------------|---------------------------|
| `SERVICE_ENABLE_DUMP1090`             | `false`                  | Disable dump1090 service  |
| `SERVICE_ENABLE_PIAWARE`              | `false`                  | Disable piaware service   |
| `SERVICE_ENABLE_FR24FEED`             | `false`                  | Disable fr24feed service  |
| `SERVICE_ENABLE_RBFEEDER`             | `false`                  | Disable rbfeeder service  |
| `SERVICE_ENABLE_HTTP`                 | `false`                  | Disable http service      |

Ex : `-e "SERVICE_ENABLE_HTTP=false"`


## FlightAware

Register on https://flightaware.com/account/join/.

Run :
```
docker run -it --rm \
	-e "SERVICE_ENABLE_DUMP1090=false" \
	-e "SERVICE_ENABLE_HTTP=false" \
	-e "SERVICE_ENABLE_FR24FEED=false" \
	-e "SERVICE_ENABLE_RBFEEDER=false" \
	thomasreiser/flightfeeder /bin/bash
```
When the container starts you should see the feeder id, note it. Wait 5 minutes and you should see a new receiver at https://fr.flightaware.com/adsb/piaware/claim (use the same IP as your docker host), claim it and exit the container.

Add the environment variable `PIAWARE_FEEDER_DASH_ID` with your feeder id.

| Environment Variable                  | Configuration property   | Default value     |
|---------------------------------------|--------------------------|-------------------|
| `PIAWARE_FEEDER_DASH_ID`              | `feeder-id`              | `YOUR_FEEDER_ID`  |


Ex : `-e "PIAWARE_RECEIVER_DASH_TYPE=other"`

## FlightRadar24

Run :
```
docker run -it --rm \
	-e "SERVICE_ENABLE_DUMP1090=false" \
	-e "SERVICE_ENABLE_HTTP=false" \
	-e "SERVICE_ENABLE_PIAWARE=false" \
	-e "SERVICE_ENABLE_FR24FEED=false" \
	-e "SERVICE_ENABLE_RBFEEDER=false" \
	thomasreiser/flightfeeder /bin/bash
```

Then : `/fr24feed/fr24feed --signup` and follow the instructions, for technical steps, your answer doesn't matter we just need the sharing key at the end.

Finally to see the sharing key run `cat /etc/fr24feed.ini`, you can now exit the container.

Add the environment variable `FR24FEED_FR24KEY` with your sharing key.


| Environment Variable                  | Configuration property   | Default value     |
|---------------------------------------|--------------------------|-------------------|
| `FR24FEED_FR24KEY`                    | `fr24key`                | `YOUR_KEY_HERE`   |

Ex : `-e "FR24FEED_FR24KEY=0123456789"`

## RadarBox

Run :
```
docker run -it --rm \
	-e "SERVICE_ENABLE_DUMP1090=false" \
	-e "SERVICE_ENABLE_HTTP=false" \
	-e "SERVICE_ENABLE_PIAWARE=false" \
	-e "SERVICE_ENABLE_FR24FEED=false" \
	-e "SERVICE_ENABLE_RBFEEDER=false" \
	thomasreiser/flightfeeder /bin/bash
```

Then : `/rbfeeder/rbfeeder --showkey --nostart` and to get your new key. Use this key then to claim this station in your RadarBox account at https://www.radarbox.com/raspberry-pi/claim.

Add the environment variable `RBFEEDER_KEY` with your sharing key.


| Environment Variable                  | Configuration property   | Default value     |
|---------------------------------------|--------------------------|-------------------|
| `RBFEEDER_KEY`                        | `[client]` -> `key`        | ``                |

Ex : `-e "RBFEEDER_KEY=0123456789"`


### Terrain-limit rings (optional):
If you don't need this feature ignore this.

Create a panorama for your receiver location on http://www.heywhatsthat.com.

| Environment Variable                  | Default value            | Description                                 |
|---------------------------------------|--------------------------|---------------------------------------------|
| `PANORAMA_ID`                         |                          | Panorama id                                 |
| `PANORAMA_ALTS`                       | `1000,10000`             | Comma seperated list of altitudes in meter  |

*Note : the panorama id value correspond to the URL at the top of the panorama http://www.heywhatsthat.com/?view=XXXX, altitudes are in meters, you can specify a list of altitudes.*

Ex : `-e "PANORAMA_ID=FRUXK2G7"`

If you don't want to download the limit every time you bring up the container you can download `http://www.heywhatsthat.com/api/upintheair.json?id=${PANORAMA_ID}&refraction=0.25&alts=${PANORAMA_ALTS}` as upintheair.json and mount it in `/usr/lib/fr24/public_html/upintheair.json`.

# Build it yourself

Clone this repo.

```docker build . ```
