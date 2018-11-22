# Eye Tracking for Everyone Pytorch re-implementation


##FeedForward on BMI Cluster
1) bash bash_pyTorch_feedForward_allSubjs.sh. This will run each subject on a different qsub job ID. You can change the qsub depends delay by changing the delay variable value. This is sensitive to out-of-memory errors.
2) qsub qsub_split_pbsdsh.sh. This will run all subjects distributed across all(10) nodes in parallel using the pbsdsh -c command. 

## Code

Requires CUDA and Python 3+ with following packages (exact version may not be necessary):

* numpy (1.13.3)
* Pillow (4.3.0)
* torch (0.3.1.post2)
* torchfile (0.1.0)
* torchvision (0.2.0)
* scipy (0.19.0)


## Contact

Please email any questions or comments to [gazecapture@gmail.com](mailto:gazecapture@gmail.com).
