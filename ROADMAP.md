# CountMADescrow Roadmap 


**FAKES/TESTS DETECTION**

- Improve the accuracy of the reliability index (which is not accurate for short periods of time and needs to be improved for long periods of time)

- Integrate this tool in the script to release the features below: https://github.com/particl/particl-insight-api

- The lifetime of a madescrow is a data which need to be taken into account in a future version to make it more accurate as most of the fake madescrow have a very short lifetime. It will require to check the global norm for the madescrows lifetime and to compare it with the lifetime of the madescrows found. This would work in the same way that how the reliability index works but instead of checking the norm fore the madesrow creations per block we would check the norm for the madescrow lifetime (the number of blocks between the madescrow creation and the madescrow release).

- Verify that the coins which are sent to the madescrows have been anonymized in an anon->blind tx in their previous tx.
***
**GRAPHS**

- Integrate gnuplot in the script and create graphs automatically
