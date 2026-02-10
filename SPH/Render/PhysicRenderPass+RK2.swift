import MetalKit

extension PhysicRenderPass {
    func runRK2(encoder: MTLComputeCommandEncoder) {
        // Force at current state
        encoder.setBuffer(self.positionBuffer, offset: 0, index: PositionBuffer.index)
        encoder.setBuffer(self.velocityBuffer, offset: 0, index: VelocityBuffer.index)

        encoder.setComputePipelineState(reorderPositionsVelocitiesPSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)

        encoder.setComputePipelineState(self.densityPSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)

        encoder.setComputePipelineState(reorderDensityPressurePSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)

        encoder.setBuffer(self.forceK1Buffer, offset: 0, index: ForceBuffer.index)
        encoder.setComputePipelineState(self.forcePSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)

        // Midpoint prediction using RK4 step1 kernel
        encoder.setComputePipelineState(rk4Step1PSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)

        // Force at midpoint
        encoder.setBuffer(self.positionKBuffer, offset: 0, index: PositionBuffer.index)
        encoder.setBuffer(self.velocityK1Buffer, offset: 0, index: VelocityBuffer.index)

        encoder.setComputePipelineState(reorderPositionsVelocitiesPSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)

        encoder.setComputePipelineState(self.densityPSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)

        encoder.setComputePipelineState(reorderDensityPressurePSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)

        encoder.setBuffer(self.forceK2Buffer, offset: 0, index: ForceBuffer.index)
        encoder.setComputePipelineState(self.forcePSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)

        // Final integration
        encoder.setBuffer(self.positionBuffer,  offset: 0, index: PositionBuffer.index)
        encoder.setBuffer(self.velocityBuffer, offset: 0, index: VelocityBuffer.index)
        encoder.setComputePipelineState(self.rk2FinalPSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)
    }
}
