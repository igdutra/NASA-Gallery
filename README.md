# NASA Gallery App – APOD Feature

<p align="center">
  <img src="Resources/ReadMe-logo.png" alt="NASA Gallery logo">
</p>

[![CI-macOS](https://github.com/igdutra/NASA-Gallery/actions/workflows/CI-macOS.yml/badge.svg)](https://github.com/igdutra/NASA-Gallery/actions/workflows/CI-macOS.yml)
[![CI-iOS](https://github.com/igdutra/NASA-Gallery/actions/workflows/CI-iOS.yml/badge.svg)](https://github.com/igdutra/NASA-Gallery/actions/workflows/CI-iOS.yml)

## BDD Specs

### Story: Daily Access to NASA's Picture of the Day

### Narrative #1: Seamless Access to Latest Images

> "As a user interested in space and online,  
I want the app to automatically load the latest NASA Picture of the Day Gallery,  
So I can easily view the newest images of the universe."

#### Scenarios (Acceptance criteria)

```
Given the user has internet connectivity,
When they request to view the APOD images,
Then the app should display the latest Gallery from NASA's remote API,
  And update the cache with this new content.
```

### Narrative #2: Viewing Images Offline

> "As a user without internet access,  
I want the app to show the most recently saved images,  
So I can enjoy images of the universe even when I'm offline."

#### Scenarios (Acceptance criteria)

```
Given the user lacks internet connectivity,
  And there is a cache of images available,
  And the cache is less than two days old,
When they request to view APOD Gallery,
Then the app should display the most recent images from the cache.

Given the user lacks internet connectivity,
  And there is a cache of images available,
  And the cache is more two days old or more,
When they request to view APOD Gallery,
Then the app should display an error message.

Given the user is offline,
  And the cache is empty,
When they request to view APOD Gallery,
Then the app should display an error message.
```


## Use Cases

### 1. Load APOD Gallery from Remote Use Case

#### Data:
- APOD API URL

#### Primary course (happy path):
1. Execute "Load APOD Gallery" command with the specified API URL.
2. System retrieves data from the provided APOD API URL.
3. System validates downloaded data.
4. System creates APOD Gallery from valid data.
5. System delivers the processed APOD Gallery for user access.

#### Invalid data – error course (sad path):
1. System delivers invalid data error.

#### No connectivity – error course (sad path):
1. System delivers connectivity error.

### 2. Load APOD Gallery from Cache Use Case 

#### Primary course:
1. Execute "Retrieve Cached APOD Gallery" command.
2. System retrieves APOD Gallery data from cache.
4. System creates APOD Gallery from valid cached data.
5. System delivers APOD Gallery.

#### Retrieval error course (sad path):
1. System delivers error.

#### Expired cache course (sad path): 
1. System delivers no gallery.

#### Empty cache course (sad path): 
1. System delivers no APOD gallery.

### 3. Validate Gallery Cache Use Case

#### Primary course:
1. Execute "Validate Cached APOD Gallery" command.
2. System retrieves gallery data from cache.
3. System validates cache age againts maximum age: verify if it is less than 2 days old.

#### Retrieval error course (sad path):
1. System deletes cache.

#### Expired cache course (sad path): 
1. System deletes cache.

### 4. Cache APOD Use Case

#### Data:
- APOD items

#### Primary course (happy path):
1. Execute "Save APOD gallery" command with the given APOD gallery.
2. System deletes old cache data.
3. System encodes APOD gallery for caching.
4. System timestamps the new cache.
5. System saves the cache with new data.
6. System delivers success message.

#### Deleting error course (sad path): 
1. System delivers error.

#### Empty cache course (sad path): 
1. System delivers error.


## Architecture

![Architecture Overview](Architecture_Overview.png)

## Model Specs

### APOD Item

| Property        | Type                | Optional |
|-----------------|---------------------|----------|
| `date`          | `String`            | No       |
| `explanation`   | `String`            | No       |
| `mediaType`     | `String`            | No       |
| `title`         | `String`            | No       |
| `url`           | `URL`               | No       |
| `copyright`     | `String`            | Yes      |
| `hdurl`         | `URL`               | Yes      |
| `thumbnailUrl`  | `URL`               | Yes      |

### Payload contract

```
GET *url* (TBD)

200 RESPONSE

[
    {
        "copyright": "\nTengyu Cai\n",
        "date": "2023-10-25",
        "explanation": "Then suddenly, the Sun appears to shrink to nothing -- only to return tomorrow.",
        "media_type": "video",
        "service_version": "v1",
        "thumbnail_url": "https://img.youtube.com/vi/J3_88eyN44w/0.jpg", 
        "title": "Gone in 60 Seconds: A Green Flash Sunset",
        "url": "https://www.youtube.com/embed/J3_88eyN44w?rel=0"
    },
    {
        "date": "2011-09-28",
        "explanation": "Instant Gallery: See recent pictures of sunspot group AR 1302.",
        "hdurl": "https://apod.nasa.gov/apod/image/1109/ar1302flare_brahic_1304.jpg",
        "media_type": "image",
        "service_version": "v1",
        "title": "Violent Sunspot Group AR 1302 Unleashes a Flare",
        "url": "https://apod.nasa.gov/apod/image/1109/ar1302flare_brahic_900.jpg"
    },
    {
        "date": "2002-06-26",
        "explanation": "The above false-color digitally enhanced image was taken with the Gemini North telescope earlier this month.",
        "hdurl": "https://apod.nasa.gov/apod/image/0206/trifid_gemini_big.jpg",
        "media_type": "image",
        "service_version": "v1",
        "title": "In the Center of the Trifid Nebula",
        "url": "https://apod.nasa.gov/apod/image/0206/trifid_gemini.jpg"
    }
]
```

### Test Name Convention

#### Tests with Condition
```test_[MethodName]_[ConditionOrScenario]_[Success/Failure-SideEffect]```   
* test_getFromURL_withDataOnHTTPURLResponse_succeeds
* test_load_on200HTTPResponseWithInvalidJSON_failsWithInvalidDataError
* test_validateCache_onExpiredCache_deletesCache

#### Testing simple outcome
```test_[Functionality]_[BehaviorOrOutcome]```
* test_apiEndToEndTests_matchesFixedTestData
* test_init_doesNotRequestDataFromURL