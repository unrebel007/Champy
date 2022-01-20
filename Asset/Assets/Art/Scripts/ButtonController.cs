using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ButtonController : MonoBehaviour
{
    [SerializeField] Animator[] actorAnimators;
    int index;

    private void Start()
    {
        CameraController.Instance.SetTarget(actorAnimators[index].transform);
    }

    public void RightButton()
    {
        index++;
        if (index > actorAnimators.Length - 1)
            index = 0;

        CameraController.Instance.SetTarget(actorAnimators[index].transform);
    }

    public void LeftButton()
    {
        index--;
        if (index < 0)
            index = actorAnimators.Length - 1;

        CameraController.Instance.SetTarget(actorAnimators[index].transform);
    }

    public void Idle()
    {
        actorAnimators[index].SetBool("isWalking", false);
    }

    public void Action()
    {
        actorAnimators[index].SetBool("isWalking", true);
        Debug.Log(actorAnimators[index]);
    }
}