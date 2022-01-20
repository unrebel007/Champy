using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Cinemachine;

public class CameraController : MonoBehaviour
{
    public static CameraController Instance;

    [SerializeField] CinemachineVirtualCamera v_Cam0;

    Transform activeActor;

    private void Awake()
    {
        Instance = this;
        activeActor = transform;
    }

    public void SetTarget(Transform actor)
    {
        if(activeActor.GetComponent<BlendShapeController>() != null)
            activeActor.GetComponent<BlendShapeController>().StopUpdating();

        activeActor = actor;

        v_Cam0.Follow = actor;
        v_Cam0.LookAt = actor;

        if(actor.GetComponent<BlendShapeController>() != null)
            StartCoroutine(actor.GetComponent<BlendShapeController>().MyUpdate());
    }
}