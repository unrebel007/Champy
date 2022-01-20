using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class BlendShapeController : MonoBehaviour
{
    [SerializeField] Canvas canvas;

    [SerializeField] SkinnedMeshRenderer smr0;
    [SerializeField] SkinnedMeshRenderer smr1;

    [SerializeField] List<Slider> sliders;
    [SerializeField] Animator anim;
    bool updating;

    private void Start()
    {
        canvas.enabled = false;
        anim = GetComponent<Animator>();
    }

   public IEnumerator MyUpdate()
    {
        yield return null;
        updating = true;
        canvas.enabled = true;

        while(updating)
        {
            UpdateBlendShapes();
            UpdateAnimationBlend();

            yield return null;
        }
    }

    private void UpdateBlendShapes()
    {
        for (int i = 0; i < sliders.Count; i++)
            smr0.SetBlendShapeWeight(i, sliders[i].value * 100);

        if (smr1 != null)
            smr1.SetBlendShapeWeight(0, sliders[2].value * 100);
    }

    private void UpdateAnimationBlend()
    {
        anim.SetFloat("walkBlend", sliders[0].value);
    }

    public void StopUpdating()
    {
        updating = false;
        canvas.enabled = false;
    }
}